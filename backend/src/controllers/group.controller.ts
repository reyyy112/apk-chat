import { Request, Response } from 'express';
import { prisma } from '../index';

export const createGroup = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || req.body.adminId || 'user_rq';
    const { name, avatar, participantIds } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Nama grup wajib diisi' });
    }

    const groupId = `group_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const allParticipantIds = new Set<string>();
    allParticipantIds.add(currentUserId);
    if (Array.isArray(participantIds)) {
      participantIds.forEach((id: string) => {
        if (id && typeof id === 'string') allParticipantIds.add(id);
      });
    }

    const creator = await prisma.user.findUnique({
      where: { id: currentUserId },
      select: { name: true },
    });
    const creatorName = creator?.name || 'Admin';

    const group = await prisma.conversation.create({
      data: {
        id: groupId,
        isGroup: true,
        groupName: name.trim(),
        groupAvatar: avatar || '',
        adminId: currentUserId,
        participants: {
          create: Array.from(allParticipantIds).map((uid) => ({
            userId: uid,
          })),
        },
        messages: {
          create: {
            senderId: currentUserId,
            content: `${creatorName} membuat grup "${name.trim()}"`,
            status: 1,
          },
        },
      },
      include: {
        participants: {
          include: {
            user: {
              select: { id: true, name: true, avatarUrl: true, phoneNumber: true },
            },
          },
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Grup berhasil dibuat',
      group: {
        id: group.id,
        name: group.groupName,
        avatar: group.groupAvatar,
        adminId: group.adminId,
        memberCount: group.participants.length,
        participants: group.participants.map((p) => p.user),
        lastMessage: group.messages[0]?.content || '',
        lastMessageTime: group.messages[0]?.createdAt || group.createdAt,
        createdAt: group.createdAt,
      },
    });
  } catch (error) {
    console.error('Error in createGroup:', error);
    return res.status(500).json({ error: 'Gagal membuat grup' });
  }
};

export const getGroups = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || 'user_rq';

    // Ensure default group_1 exists
    await prisma.conversation.upsert({
      where: { id: 'group_1' },
      update: {},
      create: {
        id: 'group_1',
        isGroup: true,
        groupName: 'Komunitas QuickChat Indonesia',
        groupAvatar: '',
        adminId: 'user_rq',
        participants: {
          create: [{ userId: currentUserId }],
        },
        messages: {
          create: {
            senderId: currentUserId,
            content: 'Selamat datang di grup resmi QuickChat!',
            status: 1,
          },
        },
      },
    });

    const groups = await prisma.conversation.findMany({
      where: {
        isGroup: true,
        OR: [
          { id: 'group_1' },
          { adminId: currentUserId },
          { participants: { some: { userId: currentUserId } } },
        ],
      },
      include: {
        participants: {
          include: {
            user: {
              select: { id: true, name: true, avatarUrl: true, phoneNumber: true },
            },
          },
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return res.status(200).json({
      success: true,
      groups: groups.map((g) => ({
        id: g.id,
        name: g.groupName || 'Grup',
        avatar: g.groupAvatar || '',
        adminId: g.adminId,
        memberCount: g.participants.length,
        participants: g.participants.map((p) => p.user),
        lastMessage: (() => {
          let text = g.messages[0]?.content || 'Belum ada pesan';
          if (text.startsWith('{')) {
            try {
              const decoded = JSON.parse(text);
              if (decoded && typeof decoded === 'object' && decoded.text !== undefined) {
                text = decoded.text;
              }
            } catch (_) {}
          }
          return text;
        })(),
        lastMessageMediaUrl: g.messages[0]?.mediaUrl || null,
        lastMessageTime: g.messages[0]?.createdAt || g.createdAt,
        createdAt: g.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error in getGroups:', error);
    return res.status(500).json({ error: 'Gagal memuat grup' });
  }
};

export const addParticipants = async (req: Request, res: Response): Promise<any> => {
  try {
    const groupId = req.params.groupId as string;
    const currentUserId = (req.headers['x-user-id'] as string) || req.body.adminId || 'user_rq';
    const { userIds } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({ error: 'Pilih setidaknya 1 pengguna untuk ditambahkan' });
    }

    const group = await prisma.conversation.findUnique({
      where: { id: groupId },
      include: { participants: true },
    });

    if (!group || !group.isGroup) {
      return res.status(404).json({ error: 'Grup tidak ditemukan' });
    }

    const existingUserIds = new Set(group.participants.map((p) => p.userId));
    const toAdd = userIds.filter((uid: string) => !existingUserIds.has(uid));

    if (toAdd.length > 0) {
      await prisma.conversationParticipant.createMany({
        data: toAdd.map((uid: string) => ({
          conversationId: groupId,
          userId: uid,
        })),
      });

      const adder = await prisma.user.findUnique({ where: { id: currentUserId }, select: { name: true } });
      await prisma.message.create({
        data: {
          conversationId: groupId,
          senderId: currentUserId,
          content: `${adder?.name || 'Admin'} menambahkan ${toAdd.length} anggota baru`,
          status: 1,
        },
      });
    }

    return res.status(200).json({ success: true, message: 'Anggota berhasil ditambahkan' });
  } catch (error) {
    console.error('Error in addParticipants:', error);
    return res.status(500).json({ error: 'Gagal menambahkan anggota' });
  }
};
