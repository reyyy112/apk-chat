import { Request, Response } from 'express';
import { prisma } from '../index';

export const getCallHistory = async (req: Request, res: Response): Promise<any> => {
  try {
    const userId = (req.headers['x-user-id'] as string) || req.query.userId as string || 'user_rq';

    const calls = await prisma.call.findMany({
      where: {
        OR: [
          { callerId: userId },
          { receiverId: userId }
        ]
      },
      include: {
        caller: {
          select: { id: true, name: true, avatarUrl: true, phoneNumber: true }
        },
        receiver: {
          select: { id: true, name: true, avatarUrl: true, phoneNumber: true }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    const formattedCalls = calls.map(c => {
      const isOutgoing = c.callerId === userId;
      const target = isOutgoing ? c.receiver : c.caller;
      return {
        id: c.id,
        isOutgoing,
        targetUser: target,
        type: c.type,
        status: c.status,
        duration: c.duration,
        createdAt: c.createdAt,
      };
    });

    return res.status(200).json({ success: true, calls: formattedCalls });
  } catch (error) {
    console.error('Error in getCallHistory:', error);
    return res.status(500).json({ error: 'Failed to fetch call history' });
  }
};

export const recordCall = async (req: Request, res: Response): Promise<any> => {
  try {
    const { callerId, receiverId, type, status, duration } = req.body;

    const call = await prisma.call.create({
      data: {
        callerId,
        receiverId,
        type: type || 'audio',
        status: status || 'completed',
        duration: duration || 0,
      }
    });

    return res.status(201).json({ success: true, call });
  } catch (error) {
    console.error('Error recording call:', error);
    return res.status(500).json({ error: 'Failed to record call' });
  }
};

export const getIceServers = async (req: Request, res: Response): Promise<any> => {
  try {
    return res.status(200).json({
      success: true,
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' },
        { urls: 'stun:stun3.l.google.com:19302' },
        { urls: 'stun:stun4.l.google.com:19302' },
        {
          urls: [
            'turn:openrelay.metered.ca:80',
            'turn:openrelay.metered.ca:443',
            'turn:openrelay.metered.ca:443?transport=tcp',
            'turns:openrelay.metered.ca:443?transport=tcp'
          ],
          username: 'openrelayproject',
          credential: 'openrelayproject',
        }
      ]
    });
  } catch (error) {
    console.error('Error in getIceServers:', error);
    return res.status(500).json({ error: 'Failed to fetch ICE servers' });
  }
};

