import crypto from 'crypto';
import { prisma } from '../index';

const hashPhone = (phone: string) => crypto.createHash('sha256').update(phone).digest('hex');

export const seedDatabase = async () => {
  try {
    // Keep existing contacts, messages, stories and users across restarts

    // Ensure sample registered accounts exist so users can search their phone numbers
    await prisma.user.upsert({
      where: { phoneNumber: '+6281234567890' },
      update: {},
      create: {
        id: 'user_rq',
        phoneNumber: '+6281234567890',
        phoneHash: hashPhone('+6281234567890'),
        name: 'rq',
        aboutStatus: 'Hey there! I am using QuickChat.',
        isOnline: true,
      }
    });

    await prisma.user.upsert({
      where: { phoneNumber: '+6281298765432' },
      update: {},
      create: {
        id: 'user_sarah',
        phoneNumber: '+6281298765432',
        phoneHash: hashPhone('+6281298765432'),
        name: 'Sarah Wilson',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        aboutStatus: 'At work 💻',
        isOnline: true,
      }
    });

    await prisma.user.upsert({
      where: { phoneNumber: '+6281311223344' },
      update: {},
      create: {
        id: 'user_budi',
        phoneNumber: '+6281311223344',
        phoneHash: hashPhone('+6281311223344'),
        name: 'Budi Santoso',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        aboutStatus: 'Busy playing futsal ⚽',
        isOnline: false,
      }
    });

    console.log('[Seed] Registered sample users ready to be searched by phone number.');
  } catch (error) {
    console.error('[Seed] Error in seedDatabase:', error);
  }
};
