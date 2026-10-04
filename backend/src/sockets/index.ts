import { Server, Socket } from 'socket.io';
import { prisma } from '../index';

// Maps userId to socketId
const activeUsers = new Map<string, string>();
// Maps socketId to userId
const socketUserMap = new Map<string, string>();

export const initializeSockets = (io: Server) => {
  // TODO: Add JWT authentication middleware for Socket.io
  
  io.on('connection', (socket: Socket) => {
    // For now, we simulate authentication by passing userId in query
    const userId = socket.handshake.query.userId as string;
    
    const registerUserSocket = (uid: string, sid: string) => {
      activeUsers.set(uid, sid);
      socketUserMap.set(sid, uid);
      socket.join(`user_${uid}`);
      console.log(`[Socket] User registered: ${uid} (socket ${sid}, room user_${uid})`);

      // Update isOnline status
      prisma.user.update({
        where: { id: uid },
        data: { isOnline: true }
      }).catch(() => {});

      // Broadcast presence change to all clients
      io.emit('user_status_changed', {
        userId: uid,
        status: 'Available',
        isOnline: true,
      });

      // Send online users to the newly connected user
      socket.emit('online_users', Array.from(activeUsers.keys()));
      io.emit('online_users', Array.from(activeUsers.keys()));
    };

    if (userId) {
      registerUserSocket(userId, socket.id);
    }

    socket.on('identify', (id: string) => {
      if (id) {
        registerUserSocket(id, socket.id);
      }
    });

    socket.on('request_online_users', () => {
      socket.emit('online_users', Array.from(activeUsers.keys()));
    });

    socket.on('send_message', async (data) => {
      // client_msg_id, conversation_id, receiver_id, content, timestamp
      console.log(`[Socket] send_message received from socket ${socket.id}:`, data);
      const senderId = socketUserMap.get(socket.id) || data.sender_id || (socket.handshake.query.userId as string);
      if (!senderId) {
        console.warn(`[Socket] send_message rejected: senderId unknown`);
        return;
      }

      // Ensure deterministic conversation ID for 1-on-1 chats
      let convId = data.conversation_id;
      if (data.receiver_id && (!convId || convId.startsWith('conv_'))) {
        const sorted = [senderId, data.receiver_id].sort();
        convId = `conv_${sorted[0]}_${sorted[1]}`;
      }

      try {
        // Ensure conversation exists
        await prisma.conversation.upsert({
          where: { id: convId },
          update: { updatedAt: new Date() },
          create: {
            id: convId,
            isGroup: false,
          }
        });

        // 1. Save message to DB (Status: 1 - Sent)
        let dbContent = data.content;
        if (data.reply_to) {
          try {
            dbContent = JSON.stringify({
              text: data.content,
              reply_to: data.reply_to,
            });
          } catch (_) {}
        }

        const message = await prisma.message.create({
          data: {
            conversationId: convId,
            senderId: senderId,
            content: dbContent,
            mediaUrl: data.media_url || data.mediaUrl || null,
            status: 1, // Sent
          }
        });

        // 2. Acknowledge as 'Sent' back to Sender (1 Checkmark)
        socket.emit('message_sent', {
          client_msg_id: data.client_msg_id,
          server_msg_id: message.id,
          conversation_id: convId,
          media_url: message.mediaUrl,
          reply_to: data.reply_to || null,
          status: 1,
          timestamp: message.createdAt
        });

        // 3. Check if conversation is a group
        const convRecord = await prisma.conversation.findUnique({
          where: { id: convId },
          include: { participants: true },
        });

        if (convRecord && convRecord.isGroup) {
          // Broadcast to all other members in the group
          for (const p of convRecord.participants) {
            if (p.userId !== senderId) {
              io.to(`user_${p.userId}`).emit('receive_message', {
                server_msg_id: message.id,
                conversation_id: convId,
                sender_id: senderId,
                content: data.content,
                media_url: message.mediaUrl,
                reply_to: data.reply_to || null,
                timestamp: message.createdAt,
              });
            }
          }
          return;
        }

        // 4. Deliver to 1-on-1 recipient if online
        const recipientRoom = `user_${data.receiver_id}`;
        const recipientSockets = await io.in(recipientRoom).fetchSockets();
        const isOnline = recipientSockets.length > 0 || activeUsers.has(data.receiver_id);
        
        if (isOnline) {
          // Update DB status to Delivered
          await prisma.message.update({
            where: { id: message.id },
            data: { status: 2 } // Delivered
          });

          // Push to Recipient room and specific socket
          io.to(recipientRoom).emit('receive_message', {
            server_msg_id: message.id,
            conversation_id: convId,
            sender_id: senderId,
            content: data.content,
            media_url: message.mediaUrl,
            reply_to: data.reply_to || null,
            timestamp: message.createdAt
          });

          const directSocketId = activeUsers.get(data.receiver_id);
          if (directSocketId && directSocketId !== socket.id) {
            io.to(directSocketId).emit('receive_message', {
              server_msg_id: message.id,
              conversation_id: convId,
              sender_id: senderId,
              content: data.content,
              media_url: message.mediaUrl,
              reply_to: data.reply_to || null,
              timestamp: message.createdAt
            });
          }

          // Tell Sender it was Delivered (2 Grey Checkmarks)
          socket.emit('message_delivered', {
            server_msg_id: message.id,
            conversation_id: convId,
            status: 2,
            delivered_at: new Date().toISOString()
          });
        }
        return;

      } catch (error) {
        console.error('[Socket] Error in send_message:', error);
      }
    });

    // ── Typing Indicator Events ─────────────────────────────────────
    socket.on('typing_start', (data) => {
      const senderId = socketUserMap.get(socket.id) || data.sender_id;
      io.to(`user_${data.receiver_id}`).emit('user_typing_start', {
        conversation_id: data.conversation_id,
        sender_id: senderId,
      });
      const recipientSocketId = activeUsers.get(data.receiver_id);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit('user_typing_start', {
          conversation_id: data.conversation_id,
          sender_id: senderId,
        });
      }
    });

    socket.on('typing_stop', (data) => {
      const senderId = socketUserMap.get(socket.id) || data.sender_id;
      io.to(`user_${data.receiver_id}`).emit('user_typing_stop', {
        conversation_id: data.conversation_id,
        sender_id: senderId,
      });
      const recipientSocketId = activeUsers.get(data.receiver_id);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit('user_typing_stop', {
          conversation_id: data.conversation_id,
          sender_id: senderId,
        });
      }
    });

    socket.on('mark_as_read', async (data) => {
      // conversation_id, message_ids, read_by_user_id, read_at
      console.log(`[Socket] mark_as_read received:`, data);

      try {
        if (!data.message_ids || data.message_ids.length === 0) return;

        // Update DB
        await prisma.message.updateMany({
          where: {
            id: { in: data.message_ids }
          },
          data: {
            status: 3, // Read
            readAt: new Date(data.read_at || Date.now())
          }
        });

        // Find who sent these messages
        const messages = await prisma.message.findMany({
          where: { id: { in: data.message_ids } },
          select: { senderId: true }
        });

        if (messages.length > 0) {
          const senderIds = Array.from(new Set(messages.map(m => m.senderId)));
          for (const sId of senderIds) {
            io.to(`user_${sId}`).emit('message_read_update', {
              conversation_id: data.conversation_id,
              message_ids: data.message_ids,
              status: 3,
              read_at: data.read_at
            });
            const senderSocketId = activeUsers.get(sId);
            if (senderSocketId) {
              io.to(senderSocketId).emit('message_read_update', {
                conversation_id: data.conversation_id,
                message_ids: data.message_ids,
                status: 3,
                read_at: data.read_at
              });
            }
          }
        }
      } catch (error) {
        console.error('[Socket] Error in mark_as_read:', error);
      }
    });

    // ── Delete Message Event ────────────────────────────────────────
    socket.on('delete_message', async (data) => {
      // data: { message_id, conversation_id, receiver_id, delete_type }
      console.log(`[Socket] delete_message received:`, data);
      try {
        const { message_id, conversation_id, receiver_id, delete_type } = data;
        if (!message_id) return;

        if (delete_type === 'for_everyone') {
          // 1. Update in DB
          await prisma.message.update({
            where: { id: message_id },
            data: {
              content: '🚫 Pesan ini telah dihapus',
              mediaUrl: null,
            }
          }).catch(e => console.warn('[Socket] Could not update deleted message in DB:', e));

          const payload = {
            message_id,
            conversation_id,
            delete_type: 'for_everyone',
          };

          // 2. Broadcast to recipient room
          if (receiver_id) {
            io.to(`user_${receiver_id}`).emit('message_deleted', payload);
            const rSocket = activeUsers.get(receiver_id);
            if (rSocket && rSocket !== socket.id) {
              io.to(rSocket).emit('message_deleted', payload);
            }
          }

          // 3. Broadcast to sender and others
          socket.emit('message_deleted', payload);
          socket.broadcast.emit('message_deleted', payload);
        }
      } catch (err) {
        console.error('[Socket] Error in delete_message:', err);
      }
    });

    // ── WebRTC & Call Signaling Events ──────────────────────────────
    socket.on('call_user', (data) => {
      // data: { recipientId, callerId, callerName, callerAvatar, mediaType, offer }
      const mediaType = data.mediaType || 'audio';
      console.log(`[WebRTC] call_user: ${data.callerId} -> ${data.recipientId} (${mediaType})`);
      
      const payload = {
        callerId: data.callerId,
        callerName: data.callerName || 'Teman',
        callerAvatar: data.callerAvatar || '',
        mediaType: mediaType,
        offer: data.offer,
      };

      // Emit to recipient room and direct socket if available
      io.to(`user_${data.recipientId}`).emit('incoming_call', payload);
      const recipientSocketId = activeUsers.get(data.recipientId);
      if (recipientSocketId && recipientSocketId !== socket.id) {
        io.to(recipientSocketId).emit('incoming_call', payload);
      }
    });

    socket.on('answer_call', (data) => {
      // data: { callerId, answer }
      console.log(`[WebRTC] answer_call to caller: ${data.callerId}`);
      const payload = {
        answer: data.answer,
        responderId: socketUserMap.get(socket.id) || data.responderId,
      };

      io.to(`user_${data.callerId}`).emit('call_accepted', payload);
      const callerSocketId = activeUsers.get(data.callerId);
      if (callerSocketId && callerSocketId !== socket.id) {
        io.to(callerSocketId).emit('call_accepted', payload);
      }
    });

    socket.on('ice_candidate', (data) => {
      // data: { targetUserId, candidate }
      const payload = {
        candidate: data.candidate,
        fromUserId: socketUserMap.get(socket.id),
      };

      io.to(`user_${data.targetUserId}`).emit('ice_candidate', payload);
      const targetSocketId = activeUsers.get(data.targetUserId);
      if (targetSocketId && targetSocketId !== socket.id) {
        io.to(targetSocketId).emit('ice_candidate', payload);
      }
    });

    socket.on('reject_call', (data) => {
      // data: { callerId, reason }
      console.log(`[WebRTC] reject_call to caller: ${data.callerId}`);
      const payload = {
        reason: data.reason || 'declined',
        responderId: socketUserMap.get(socket.id) || data.responderId,
      };

      io.to(`user_${data.callerId}`).emit('call_rejected', payload);
      const callerSocketId = activeUsers.get(data.callerId);
      if (callerSocketId && callerSocketId !== socket.id) {
        io.to(callerSocketId).emit('call_rejected', payload);
      }
    });

    socket.on('end_call', (data) => {
      // data: { targetUserId, duration }
      console.log(`[WebRTC] end_call with: ${data.targetUserId}`);
      const payload = {
        duration: data.duration,
        endedBy: socketUserMap.get(socket.id) || data.endedBy,
      };

      io.to(`user_${data.targetUserId}`).emit('call_ended', payload);
      const targetSocketId = activeUsers.get(data.targetUserId);
      if (targetSocketId && targetSocketId !== socket.id) {
        io.to(targetSocketId).emit('call_ended', payload);
      }
    });

    // Real-time Story & Viewers
    socket.on('post_story', (data) => {
      console.log(`[Socket] post_story by user:`, socketUserMap.get(socket.id));
      socket.broadcast.emit('new_story', data);
    });

    socket.on('view_story', (data) => {
      console.log(`[Socket] view_story for story: ${data?.story_id} by: ${data?.viewer?.name}`);
      io.emit('story_viewed', data);
    });

    socket.on('disconnect', async () => {
      console.log(`[Socket] User disconnected: ${socket.id}`);
      const userId = socketUserMap.get(socket.id);
      
      if (userId) {
        socketUserMap.delete(socket.id);
        const remainingSockets = await io.in(`user_${userId}`).fetchSockets();
        if (remainingSockets.length === 0) {
          activeUsers.delete(userId);
          
          // Update lastSeen and isOnline status in DB
          prisma.user.update({
            where: { id: userId },
            data: { 
              isOnline: false,
              lastSeen: new Date()
            }
          }).catch(() => {});

          // Broadcast offline status
          io.emit('user_status_changed', {
            userId: userId,
            status: 'Offline',
            isOnline: false,
          });
        }
      }
    });
  });
};
