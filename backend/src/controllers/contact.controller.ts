import { Request, Response } from 'express';
import { prisma, io } from '../index';
import crypto from 'crypto';

export const resetContacts = async (req: Request, res: Response): Promise<any> => {
  try {
    await prisma.contact.deleteMany({});
    return res.status(200).json({ success: true, message: 'Kontak berhasil direset ke 0' });
  } catch (error) {
    return res.status(500).json({ error: 'Gagal reset kontak' });
  }
};

export const getConversationMessages = async (req: Request, res: Response): Promise<any> => {
  try {
    const conversationId = req.params.conversationId as string;
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || 'user_rq';

    const messages = await prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        conversationId: true,
        senderId: true,
        content: true,
        mediaUrl: true,
        status: true,
        createdAt: true,
        readAt: true,
      }
    });

    return res.status(200).json({
      success: true,
      messages: messages.map(m => ({
        server_msg_id: m.id,
        content: m.content,
        media_url: m.mediaUrl,
        isMe: m.senderId === currentUserId,
        status: m.status,
        timestamp: m.createdAt,
      }))
    });
  } catch (error) {
    console.error('Error in getConversationMessages:', error);
    return res.status(500).json({ error: 'Gagal memuat pesan' });
  }
};

export const getContacts = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || req.query.userId as string || 'user_rq';

    const contacts = await prisma.contact.findMany({
      where: { userId: currentUserId },
      include: {
        targetUser: {
          select: {
            id: true,
            name: true,
            phoneNumber: true,
            avatarUrl: true,
            aboutStatus: true,
            isOnline: true,
            lastSeen: true,
          }
        }
      }
    });

    const knownUserIds = new Set<string>(contacts.map(c => c.targetUserId));
    
    // Also include any users who have had 1-on-1 conversations with currentUserId but aren't in contacts list
    const extraConvs = await prisma.conversation.findMany({
      where: {
        id: { contains: currentUserId },
        isGroup: false,
      }
    });

    const extraUserIds: string[] = [];
    for (const ec of extraConvs) {
      const parts = ec.id.replace('conv_', '').split('_');
      const other = parts.find(id => id !== currentUserId);
      if (other && !knownUserIds.has(other)) {
        extraUserIds.push(other);
        knownUserIds.add(other);
      }
    }

    let extraUsers: any[] = [];
    if (extraUserIds.length > 0) {
      extraUsers = await prisma.user.findMany({
        where: { id: { in: extraUserIds } },
        select: {
          id: true,
          name: true,
          phoneNumber: true,
          avatarUrl: true,
          aboutStatus: true,
          isOnline: true,
          lastSeen: true,
        }
      });
    }

    // Build list of all conversation IDs
    const allItems: any[] = [
      ...contacts.map(c => ({
        ...c.targetUser,
        isMutualContact: c.isMutualContact,
        contactId: c.id,
      })),
      ...extraUsers.map(u => ({
        ...u,
        isMutualContact: false,
        contactId: null,
      }))
    ];

    const allConvIds: string[] = allItems.map(item => {
      const sorted = [currentUserId, item.id].sort();
      return `conv_${sorted[0]}_${sorted[1]}`;
    });

    // Query messages in all conversations
    const messages = await prisma.message.findMany({
      where: { conversationId: { in: allConvIds } },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        conversationId: true,
        senderId: true,
        content: true,
        mediaUrl: true,
        status: true,
        createdAt: true,
      }
    });

    const lastMessageMap = new Map<string, any>();
    const unreadCountMap = new Map<string, number>();

    for (const m of messages) {
      if (!lastMessageMap.has(m.conversationId)) {
        let text = m.content || '';
        if (text.startsWith('{')) {
          try {
            const decoded = JSON.parse(text);
            if (decoded && typeof decoded === 'object' && decoded.text !== undefined) {
              text = decoded.text;
            }
          } catch (_) {}
        }

        let mediaUrl = m.mediaUrl || null;
        if (mediaUrl && mediaUrl.includes('localhost:3000')) {
          mediaUrl = mediaUrl.replace('http://localhost:3000', 'https://tumor-oliver-interest-flickr.trycloudflare.com');
        }

        lastMessageMap.set(m.conversationId, {
          id: m.id,
          content: text,
          mediaUrl: mediaUrl,
          senderId: m.senderId,
          isMe: m.senderId === currentUserId,
          status: m.status,
          timestamp: m.createdAt,
        });
      }

      // Count unread: incoming messages that are not yet marked as read (status < 3)
      if (m.senderId !== currentUserId && m.status < 3) {
        unreadCountMap.set(m.conversationId, (unreadCountMap.get(m.conversationId) || 0) + 1);
      }
    }

    const enrichedContacts = allItems.map(item => {
      const sorted = [currentUserId, item.id].sort();
      const convId = `conv_${sorted[0]}_${sorted[1]}`;
      return {
        ...item,
        lastMessage: lastMessageMap.get(convId) || null,
        unreadCount: unreadCountMap.get(convId) || 0,
      };
    });

    // Sort: Newest message at the top!
    enrichedContacts.sort((a, b) => {
      const timeA = a.lastMessage ? new Date(a.lastMessage.timestamp).getTime() : 0;
      const timeB = b.lastMessage ? new Date(b.lastMessage.timestamp).getTime() : 0;
      if (timeA !== timeB) return timeB - timeA;
      return (a.name || '').localeCompare(b.name || '');
    });

    return res.status(200).json({
      success: true,
      contacts: enrichedContacts,
    });
  } catch (error) {
    console.error('Error in getContacts:', error);
    return res.status(500).json({ error: 'Failed to fetch contacts' });
  }
};

export const searchContactByPhone = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || 'user_rq';
    const query = ((req.query.phone as string) || '').trim();

    if (!query) {
      return res.status(400).json({ error: 'Masukkan nomor telepon yang ingin dicari' });
    }

    // Normalize phone query to match variations like 08..., +62..., 62...
    const cleanDigits = query.replace(/\D/g, '');
    let coreDigits = cleanDigits;
    if (cleanDigits.startsWith('62')) {
      coreDigits = cleanDigits.slice(2);
    } else if (cleanDigits.startsWith('0')) {
      coreDigits = cleanDigits.slice(1);
    }

    const searchVariants = Array.from(new Set([
      query,
      cleanDigits,
      coreDigits,
      `+62${coreDigits}`,
      `62${coreDigits}`,
      `0${coreDigits}`,
    ])).filter(v => v.length >= 3);

    // Search by phone number in database
    const users = await prisma.user.findMany({
      where: {
        id: { not: currentUserId }, // exclude self
        OR: searchVariants.map(variant => ({
          phoneNumber: { contains: variant }
        }))
      },
      select: {
        id: true,
        name: true,
        phoneNumber: true,
        avatarUrl: true,
        aboutStatus: true,
        isOnline: true,
        lastSeen: true,
      }
    });

    // Check relationship with current user
    const userContacts = await prisma.contact.findMany({
      where: { userId: currentUserId }
    });
    const contactMap = new Map(userContacts.map(c => [c.targetUserId, c.isMutualContact]));

    const results = users.map(u => ({
      ...u,
      isAdded: contactMap.has(u.id),
      isMutualContact: contactMap.get(u.id) || false,
    }));

    return res.status(200).json({
      success: true,
      users: results,
    });
  } catch (error) {
    console.error('Error in searchContactByPhone:', error);
    return res.status(500).json({ error: 'Gagal mencari nomor telepon' });
  }
};

export const getAllUsers = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || req.query.userId as string || 'user_rq';

    const users = await prisma.user.findMany({
      where: {
        id: { not: currentUserId }
      },
      select: {
        id: true,
        name: true,
        phoneNumber: true,
        avatarUrl: true,
        aboutStatus: true,
        isOnline: true,
        lastSeen: true,
      }
    });

    // Check which users are mutual contacts
    const userContacts = await prisma.contact.findMany({
      where: { userId: currentUserId }
    });
    const contactMap = new Map(userContacts.map(c => [c.targetUserId, c.isMutualContact]));

    const usersWithContactStatus = users.map(u => ({
      ...u,
      isAdded: contactMap.has(u.id),
      isMutualContact: contactMap.get(u.id) || false,
    }));

    return res.status(200).json({
      success: true,
      users: usersWithContactStatus,
    });
  } catch (error) {
    console.error('Error in getAllUsers:', error);
    return res.status(500).json({ error: 'Failed to fetch users' });
  }
};

export const addContact = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';
    const { targetPhoneNumber, targetUserId } = req.body;

    // Find target user
    let targetUser;
    if (targetUserId) {
      targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
    } else if (targetPhoneNumber) {
      targetUser = await prisma.user.findUnique({ where: { phoneNumber: targetPhoneNumber } });
    }

    if (!targetUser) {
      return res.status(404).json({ error: 'User tidak ditemukan' });
    }

    if (targetUser.id === currentUserId) {
      return res.status(400).json({ error: 'Tidak dapat menambahkan diri sendiri' });
    }

    // Check if target user has already saved current user
    const reciprocalContact = await prisma.contact.findUnique({
      where: {
        userId_targetUserId: {
          userId: targetUser.id,
          targetUserId: currentUserId,
        }
      }
    });

    const isMutual = !!reciprocalContact;

    // Create or update current user -> target user contact
    const contact = await prisma.contact.upsert({
      where: {
        userId_targetUserId: {
          userId: currentUserId,
          targetUserId: targetUser.id,
        }
      },
      update: {
        isMutualContact: isMutual,
      },
      create: {
        userId: currentUserId,
        targetUserId: targetUser.id,
        isMutualContact: isMutual,
      }
    });

    // If mutual, update the reciprocal contact too
    if (isMutual) {
      await prisma.contact.update({
        where: { id: reciprocalContact.id },
        data: { isMutualContact: true }
      });
      io.to(`user_${targetUser.id}`).emit('friend_request_accepted', { userId: currentUserId });
      io.to(`user_${currentUserId}`).emit('friend_request_accepted', { userId: targetUser.id });
    } else {
      io.to(`user_${targetUser.id}`).emit('friend_request_received', { userId: currentUserId });
    }

    return res.status(200).json({
      success: true,
      message: isMutual ? 'Berhasil menjadi Mutual Friends!' : 'Kontak berhasil disimpan',
      contact: {
        ...targetUser,
        isMutualContact: isMutual,
      }
    });
  } catch (error) {
    console.error('Error in addContact:', error);
    return res.status(500).json({ error: 'Failed to add contact' });
  }
};

export const getFriendRequests = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || 'user_rq';

    // Incoming requests: others added currentUserId, but not mutual yet
    const incomingContacts = await prisma.contact.findMany({
      where: {
        targetUserId: currentUserId,
        isMutualContact: false,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phoneNumber: true,
            avatarUrl: true,
            aboutStatus: true,
            isOnline: true,
            lastSeen: true,
          }
        }
      }
    });

    // Outgoing requests: currentUserId added others, waiting for confirmation
    const outgoingContacts = await prisma.contact.findMany({
      where: {
        userId: currentUserId,
        isMutualContact: false,
      },
      include: {
        targetUser: {
          select: {
            id: true,
            name: true,
            phoneNumber: true,
            avatarUrl: true,
            aboutStatus: true,
            isOnline: true,
            lastSeen: true,
          }
        }
      }
    });

    return res.status(200).json({
      success: true,
      incoming: incomingContacts.map(c => ({
        contactId: c.id,
        createdAt: c.updatedAt,
        ...c.user,
      })),
      outgoing: outgoingContacts.map(c => ({
        contactId: c.id,
        createdAt: c.updatedAt,
        ...c.targetUser,
      })),
    });
  } catch (error) {
    console.error('Error in getFriendRequests:', error);
    return res.status(500).json({ error: 'Gagal memuat permintaan pertemanan' });
  }
};

export const acceptFriendRequest = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';
    const { targetUserId } = req.body;

    if (!targetUserId) {
      return res.status(400).json({ error: 'targetUserId wajib diisi' });
    }

    // Check sender -> current contact
    const incomingContact = await prisma.contact.findUnique({
      where: {
        userId_targetUserId: {
          userId: targetUserId,
          targetUserId: currentUserId,
        }
      }
    });

    if (!incomingContact) {
      return res.status(404).json({ error: 'Permintaan pertemanan tidak ditemukan' });
    }

    // Update incoming contact to mutual
    await prisma.contact.update({
      where: { id: incomingContact.id },
      data: { isMutualContact: true }
    });

    // Upsert current -> sender contact as mutual
    await prisma.contact.upsert({
      where: {
        userId_targetUserId: {
          userId: currentUserId,
          targetUserId: targetUserId,
        }
      },
      update: { isMutualContact: true },
      create: {
        userId: currentUserId,
        targetUserId: targetUserId,
        isMutualContact: true,
      }
    });

    const friendUser = await prisma.user.findUnique({
      where: { id: targetUserId },
      select: {
        id: true,
        name: true,
        phoneNumber: true,
        avatarUrl: true,
        aboutStatus: true,
        isOnline: true,
        lastSeen: true,
      }
    });

    io.to(`user_${targetUserId}`).emit('friend_request_accepted', { userId: currentUserId });
    io.to(`user_${currentUserId}`).emit('friend_request_accepted', { userId: targetUserId });

    return res.status(200).json({
      success: true,
      message: 'Permintaan pertemanan diterima! Sekarang Anda berteman.',
      friend: friendUser,
    });
  } catch (error) {
    console.error('Error in acceptFriendRequest:', error);
    return res.status(500).json({ error: 'Gagal menerima permintaan pertemanan' });
  }
};

export const rejectFriendRequest = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';
    const { targetUserId } = req.body;

    await prisma.contact.deleteMany({
      where: {
        userId: targetUserId,
        targetUserId: currentUserId,
        isMutualContact: false,
      }
    });

    io.to(`user_${targetUserId}`).emit('friend_request_rejected', { userId: currentUserId });
    io.to(`user_${currentUserId}`).emit('friend_request_rejected', { userId: targetUserId });

    return res.status(200).json({
      success: true,
      message: 'Permintaan pertemanan ditolak',
    });
  } catch (error) {
    console.error('Error in rejectFriendRequest:', error);
    return res.status(500).json({ error: 'Gagal menolak permintaan pertemanan' });
  }
};

export const getUserProfile = async (req: Request, res: Response): Promise<any> => {
  try {
    const userId = req.params.userId as string;
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.currentUserId as string) || 'user_rq';

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        phoneNumber: true,
        avatarUrl: true,
        aboutStatus: true,
        isOnline: true,
        lastSeen: true,
        createdAt: true,
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'Pengguna tidak ditemukan' });
    }

    // Check mutual friendship
    const contact = await prisma.contact.findUnique({
      where: {
        userId_targetUserId: {
          userId: currentUserId,
          targetUserId: userId,
        }
      }
    });

    const isMutual = contact?.isMutualContact || false;

    // Gather real photos uploaded by this user to their profile gallery
    const userPhotos = await prisma.userPhoto.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    const publicDomain = 'https://tumor-oliver-interest-flickr.trycloudflare.com';
    const uploadedPhotos: Array<{ id: string; url: string; caption?: string; createdAt: Date; type: string }> = [];
    const seenUrls = new Set<string>();

    for (const p of userPhotos) {
      if (p.url && !seenUrls.has(p.url)) {
        seenUrls.add(p.url);
        const normalizedUrl = p.url.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicDomain);
        uploadedPhotos.push({
          id: p.id,
          url: normalizedUrl,
          caption: p.caption || undefined,
          createdAt: p.createdAt,
          type: 'gallery',
        });
      }
    }

    // Provide social stats and photo gallery
    const profileData = {
      ...user,
      isMutualContact: isMutual,
      postsCount: uploadedPhotos.length,
      followersCount: isMutual ? 1 : 0,
      followingCount: isMutual ? 1 : 0,
      bio: user.aboutStatus || 'Hey there! I am using QuickChat.',
      photos: uploadedPhotos.map(p => p.url),
      photosDetail: uploadedPhotos,
    };

    return res.status(200).json({ success: true, profile: profileData });
  } catch (error) {
    console.error('Error in getUserProfile:', error);
    return res.status(500).json({ error: 'Failed to fetch user profile' });
  }
};

export const syncContacts = async (req: Request, res: Response): Promise<any> => {
  const currentUserId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';
  const { phoneHashes } = req.body;

  if (!currentUserId || !Array.isArray(phoneHashes)) {
    return res.status(400).json({ error: 'Invalid payload' });
  }

  try {
    const registeredContacts = await prisma.user.findMany({
      where: {
        phoneHash: { in: phoneHashes },
        id: { not: currentUserId }
      }
    });

    const targetUserIds = registeredContacts.map(u => u.id);

    for (const targetId of targetUserIds) {
      await prisma.contact.upsert({
        where: {
          userId_targetUserId: {
            userId: currentUserId,
            targetUserId: targetId
          }
        },
        update: {},
        create: {
          userId: currentUserId,
          targetUserId: targetId,
          isMutualContact: false
        }
      });
    }

    const reciprocalContacts = await prisma.contact.findMany({
      where: {
        userId: { in: targetUserIds },
        targetUserId: currentUserId
      }
    });

    const mutualUserIds = reciprocalContacts.map(c => c.userId);

    if (mutualUserIds.length > 0) {
      await prisma.contact.updateMany({
        where: {
          userId: currentUserId,
          targetUserId: { in: mutualUserIds }
        },
        data: { isMutualContact: true }
      });

      await prisma.contact.updateMany({
        where: {
          userId: { in: mutualUserIds },
          targetUserId: currentUserId
        },
        data: { isMutualContact: true }
      });
    }

    const updatedContacts = await prisma.contact.findMany({
      where: { userId: currentUserId },
      include: {
        targetUser: {
          select: { id: true, name: true, phoneNumber: true, avatarUrl: true, aboutStatus: true, isOnline: true }
        }
      }
    });

    return res.status(200).json({
      message: 'Contacts synced successfully',
      syncedCount: targetUserIds.length,
      mutualCount: mutualUserIds.length,
      contacts: updatedContacts.map(c => ({
        ...c.targetUser,
        isMutualContact: c.isMutualContact
      }))
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to sync contacts' });
  }
};
