import { Request, Response } from 'express';
import { prisma } from '../index';

export const createStory = async (req: Request, res: Response): Promise<any> => {
  try {
    const { mediaUrl, caption } = req.body;
    const userId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';

    if (!mediaUrl && !caption) {
      return res.status(400).json({ error: 'Media URL atau teks cerita wajib diisi' });
    }

    // Expiration 24 hours
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const story = await prisma.story.create({
      data: {
        userId,
        mediaUrl: mediaUrl || '',
        caption: caption || '',
        expiresAt,
      },
      include: {
        user: {
          select: { id: true, name: true, avatarUrl: true },
        },
      },
    });

    return res.status(201).json({ success: true, message: 'Story created successfully', story });
  } catch (error) {
    console.error('Error creating story:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const getStories = async (req: Request, res: Response): Promise<any> => {
  try {
    const userId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || 'user_rq';

    // 1. Fetch active stories within 24 hours
    const publicDomain = 'https://tumor-oliver-interest-flickr.trycloudflare.com';

    // In this collaborative chat app, display active stories from all connected contacts,
    // active conversation partners, and all registered friends in the network
    const stories = await prisma.story.findMany({
      where: {
        expiresAt: { gt: new Date() },
      },
      include: {
        user: {
          select: { id: true, name: true, avatarUrl: true, phoneNumber: true },
        },
        viewers: {
          include: {
            user: {
              select: { id: true, name: true, avatarUrl: true, phoneNumber: true },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Group stories by user with normalized media and avatar URLs
    const groupedStories = stories.reduce((acc, story) => {
      const normAvatar = story.user.avatarUrl
        ? story.user.avatarUrl.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicDomain)
        : null;

      if (!acc[story.userId]) {
        acc[story.userId] = {
          userId: story.userId,
          user: {
            ...story.user,
            avatarUrl: normAvatar,
          },
          stories: [],
        };
      }

      const normMediaUrl = story.mediaUrl
        ? story.mediaUrl.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicDomain)
        : '';

      acc[story.userId].stories.push({
        id: story.id,
        mediaUrl: normMediaUrl,
        caption: story.caption,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        viewersCount: story.viewers.length,
        viewers: story.viewers.map((v) => ({
          userId: v.userId,
          name: v.user.name,
          avatarUrl: v.user.avatarUrl
            ? v.user.avatarUrl.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicDomain)
            : null,
          phoneNumber: v.user.phoneNumber,
          viewedAt: v.viewedAt,
        })),
        isViewedByMe: story.viewers.some((v) => v.userId === userId),
      });
      return acc;
    }, {} as Record<string, any>);

    return res.status(200).json({ success: true, data: Object.values(groupedStories) });
  } catch (error) {
    console.error('Error fetching stories:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const viewStory = async (req: Request, res: Response): Promise<any> => {
  try {
    const storyId = req.params.storyId as string;
    const userId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';

    const story = await prisma.story.findUnique({
      where: { id: storyId },
    });

    if (!story) {
      return res.status(404).json({ error: 'Story tidak ditemukan' });
    }

    // Do not record creator viewing their own story
    if (story.userId === userId) {
      return res.status(200).json({ success: true, message: 'Creator view ignored' });
    }

    // Upsert viewer record
    const viewer = await prisma.storyViewer.upsert({
      where: {
        storyId_userId: {
          storyId,
          userId,
        },
      },
      update: {
        viewedAt: new Date(),
      },
      create: {
        storyId,
        userId,
      },
    });

    return res.status(200).json({ success: true, viewer });
  } catch (error) {
    console.error('Error in viewStory:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const getStoryViewers = async (req: Request, res: Response): Promise<any> => {
  try {
    const storyId = req.params.storyId as string;

    const viewers = await prisma.storyViewer.findMany({
      where: { storyId },
      include: {
        user: {
          select: { id: true, name: true, avatarUrl: true, phoneNumber: true },
        },
      },
      orderBy: {
        viewedAt: 'desc',
      },
    });

    return res.status(200).json({
      success: true,
      viewers: viewers.map((v) => ({
        userId: v.userId,
        name: v.user.name,
        avatarUrl: v.user.avatarUrl,
        phoneNumber: v.user.phoneNumber,
        viewedAt: v.viewedAt,
      })),
    });
  } catch (error) {
    console.error('Error in getStoryViewers:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteStory = async (req: Request, res: Response): Promise<any> => {
  try {
    const storyId = req.params.storyId as string;
    const userId = (req.headers['x-user-id'] as string) || req.body.userId || 'user_rq';

    const story = await prisma.story.findUnique({
      where: { id: storyId },
    });

    if (!story) {
      return res.status(404).json({ error: 'Story tidak ditemukan' });
    }

    if (story.userId !== userId) {
      return res.status(403).json({ error: 'Tidak memiliki izin untuk menghapus status ini' });
    }

    await prisma.storyViewer.deleteMany({
      where: { storyId },
    });

    await prisma.story.delete({
      where: { id: storyId },
    });

    return res.status(200).json({ success: true, message: 'Status berhasil dihapus' });
  } catch (error) {
    console.error('Error in deleteStory:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

