import { Request, Response } from 'express';
import { prisma } from '../index';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { uploadBufferToSupabase, deleteFromSupabase, STORAGE_BUCKET } from '../config/supabase';

export const loginOrRegister = async (req: Request, res: Response): Promise<any> => {
  const { phoneNumber, name } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ error: 'Nomor telepon wajib diisi' });
  }

  const phone = phoneNumber.trim();

  try {
    const phoneHash = crypto.createHash('sha256').update(phone).digest('hex');

    let user = await prisma.user.findUnique({
      where: { phoneNumber: phone }
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          phoneNumber: phone,
          phoneHash,
          name: name || (phone.includes('12345') ? 'rq' : `User_${phone.slice(-4)}`),
          isOnline: true,
          aboutStatus: 'Hey there! I am using QuickChat.',
        }
      });
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { isOnline: true }
      });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Login berhasil',
      token,
      user
    });
  } catch (error) {
    console.error('Error in loginOrRegister:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const registerUser = async (req: Request, res: Response): Promise<any> => {
  const { phoneNumber, name, aboutStatus } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ error: 'Nomor telepon wajib diisi' });
  }
  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Nama lengkap wajib diisi' });
  }

  const phone = phoneNumber.trim();

  try {
    const phoneHash = crypto.createHash('sha256').update(phone).digest('hex');

    let user = await prisma.user.findUnique({
      where: { phoneNumber: phone }
    });

    if (user) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          name: name.trim(),
          isOnline: true,
          aboutStatus: aboutStatus || user.aboutStatus,
        }
      });
    } else {
      user = await prisma.user.create({
        data: {
          phoneNumber: phone,
          phoneHash,
          name: name.trim(),
          isOnline: true,
          aboutStatus: aboutStatus || 'Hey there! I am using QuickChat.',
          avatarUrl: null,
        }
      });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Pendaftaran berhasil',
      token,
      user
    });
  } catch (error) {
    console.error('Error in registerUser:', error);
    return res.status(500).json({ error: 'Gagal melakukan pendaftaran akun' });
  }
};

export const requestOtp = async (req: Request, res: Response): Promise<any> => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ error: 'Phone number is required' });
  }

  console.log(`[AUTH] Sending OTP to ${phoneNumber}...`);
  return res.status(200).json({ message: 'OTP sent successfully (Simulated)' });
};

export const verifyOtp = async (req: Request, res: Response): Promise<any> => {
  const { phoneNumber, otp, phoneHash, name } = req.body;
  
  if (!phoneNumber || !otp || !phoneHash) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  if (otp !== '123456') {
    return res.status(401).json({ error: 'Invalid OTP' });
  }

  try {
    let user = await prisma.user.findUnique({
      where: { phoneNumber }
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          phoneNumber,
          phoneHash,
          name: name || 'New User',
          isOnline: true
        }
      });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      message: 'Authentication successful',
      token,
      user
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const getMyProfile = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || (req as any).userId;
    if (!currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
      where: { id: currentUserId },
      include: {
        photos: {
          orderBy: { createdAt: 'desc' }
        }
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User tidak ditemukan' });
    }

    return res.status(200).json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        avatarUrl: user.avatarUrl,
        aboutStatus: user.aboutStatus,
        createdAt: user.createdAt,
        photos: user.photos,
      }
    });
  } catch (error) {
    console.error('Error in getMyProfile:', error);
    return res.status(500).json({ error: 'Gagal mengambil data profil' });
  }
};

export const updateUserProfile = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.body.userId as string) || (req as any).userId;
    if (!currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { name, aboutStatus, avatarUrl } = req.body;
    const updateData: any = {};
    if (name !== undefined) updateData.name = name.trim();
    if (aboutStatus !== undefined) updateData.aboutStatus = aboutStatus.trim();
    if (avatarUrl !== undefined) updateData.avatarUrl = avatarUrl.trim();

    const updatedUser = await prisma.user.update({
      where: { id: currentUserId },
      data: updateData
    });

    return res.status(200).json({
      success: true,
      message: 'Profil berhasil diperbarui',
      user: updatedUser
    });
  } catch (error) {
    console.error('Error in updateUserProfile:', error);
    return res.status(500).json({ error: 'Gagal memperbarui profil' });
  }
};

export const getUserPhotos = async (req: Request, res: Response): Promise<any> => {
  try {
    const targetUserId = (req.query.userId as string) || (req.headers['x-user-id'] as string) || (req as any).userId;
    if (!targetUserId) {
      return res.status(400).json({ error: 'User ID diperlukan' });
    }

    const photos = await prisma.userPhoto.findMany({
      where: { userId: targetUserId },
      orderBy: { createdAt: 'desc' }
    });

    const publicDomain = 'https://tumor-oliver-interest-flickr.trycloudflare.com';
    const normalizedPhotos = photos.map(p => ({
      ...p,
      url: p.url.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicDomain),
    }));

    return res.status(200).json({
      success: true,
      photos: normalizedPhotos
    });
  } catch (error) {
    console.error('Error in getUserPhotos:', error);
    return res.status(500).json({ error: 'Gagal mengambil foto' });
  }
};

export const addUserPhoto = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.body.userId as string) || (req as any).userId;
    if (!currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { url, caption } = req.body;
    if (!url || !url.trim()) {
      return res.status(400).json({ error: 'URL foto wajib diisi' });
    }

    const newPhoto = await prisma.userPhoto.create({
      data: {
        userId: currentUserId,
        url: url.trim(),
        caption: caption ? caption.trim() : null
      }
    });

    return res.status(201).json({
      success: true,
      message: 'Foto berhasil ditambahkan',
      photo: newPhoto
    });
  } catch (error) {
    console.error('Error in addUserPhoto:', error);
    return res.status(500).json({ error: 'Gagal menambahkan foto' });
  }
};

export const deleteUserPhoto = async (req: Request, res: Response): Promise<any> => {
  try {
    const currentUserId = (req.headers['x-user-id'] as string) || (req.query.userId as string) || (req as any).userId;
    const photoId = req.params.photoId as string;

    if (!photoId) {
      return res.status(400).json({ error: 'Photo ID wajib disertakan' });
    }

    const photo = await prisma.userPhoto.findFirst({
      where: { id: photoId, userId: currentUserId }
    });

    if (photo) {
      // Check if photo is hosted on Supabase Storage
      if (photo.url && photo.url.includes('/storage/v1/object/public/')) {
        const parts = photo.url.split('/');
        const filename = parts[parts.length - 1];
        if (filename) {
          await deleteFromSupabase(filename);
        }
      } else if (photo.url && photo.url.includes('/uploads/')) {
        const parts = photo.url.split('/uploads/');
        const filename = parts[1];
        if (filename) {
          const localPath = path.resolve(__dirname, '../../uploads', filename);
          if (fs.existsSync(localPath)) {
            try { fs.unlinkSync(localPath); } catch {}
          }
        }
      }

      await prisma.userPhoto.delete({
        where: { id: photoId }
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Foto berhasil dihapus'
    });
  } catch (error) {
    console.error('Error in deleteUserPhoto:', error);
    return res.status(500).json({ error: 'Gagal menghapus foto' });
  }
};

export const uploadImageFile = async (req: Request, res: Response): Promise<any> => {
  try {
    const { base64, filename, ext } = req.body;
    if (!base64) {
      return res.status(400).json({ error: 'Data base64 wajib dikirim' });
    }

    const cleanBase64 = base64.replace(/^data:[a-zA-Z0-9\/\-]+;base64,/, '');
    const buffer = Buffer.from(cleanBase64, 'base64');

    const fileExt = (ext || (filename && filename.includes('.') ? filename.split('.').pop() : 'jpg')).toLowerCase();
    
    const audioExts = ['m4a', 'webm', 'mp3', 'wav', 'aac', 'ogg'];
    const imageExts = ['png', 'jpg', 'jpeg', 'gif', 'webp'];
    
    let safeExt = 'jpg';
    let mimeType = 'image/jpeg';
    let prefix = 'img';

    if (audioExts.includes(fileExt)) {
      safeExt = fileExt;
      prefix = 'audio';
      switch (fileExt) {
        case 'webm':
          mimeType = 'audio/webm';
          break;
        case 'm4a':
          mimeType = 'audio/mp4';
          break;
        case 'mp3':
          mimeType = 'audio/mpeg';
          break;
        case 'wav':
          mimeType = 'audio/wav';
          break;
        case 'ogg':
          mimeType = 'audio/ogg';
          break;
        case 'aac':
          mimeType = 'audio/aac';
          break;
        default:
          mimeType = 'audio/mpeg';
      }
    } else {
      safeExt = imageExts.includes(fileExt) ? fileExt : 'jpg';
      mimeType = safeExt === 'jpg' ? 'image/jpeg' : `image/${safeExt}`;
    }

    const uniqueName = `${prefix}_${Date.now()}_${crypto.randomBytes(4).toString('hex')}.${safeExt}`;

    // 1. Try uploading to Supabase Storage first
    const supabaseResult = await uploadBufferToSupabase(uniqueName, buffer, mimeType);
    if (supabaseResult.success && supabaseResult.url) {
      return res.status(200).json({
        success: true,
        message: 'Media berhasil diunggah ke Supabase Storage',
        url: supabaseResult.url,
        filename: uniqueName,
      });
    }

    // 2. Fallback to local storage if Supabase credentials are not set or upload failed
    console.warn('Supabase upload fell back to local storage:', supabaseResult.error);
    const uploadsDir = path.resolve(__dirname, '../../uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const filePath = path.join(uploadsDir, uniqueName);
    await fs.promises.writeFile(filePath, buffer);

    let host = (req.headers['x-forwarded-host'] as string) || req.get('host') || 'tumor-oliver-interest-flickr.trycloudflare.com';
    let protocol = (req.headers['x-forwarded-proto'] as string) || req.protocol || 'https';
    if (host.includes('localhost') || host.includes('127.0.0.1')) {
      host = 'tumor-oliver-interest-flickr.trycloudflare.com';
      protocol = 'https';
    }
    const fullUrl = `${protocol}://${host}/uploads/${uniqueName}`;

    return res.status(200).json({
      success: true,
      message: 'Media berhasil diunggah (lokal)',
      url: fullUrl,
      filename: uniqueName,
    });
  } catch (error) {
    console.error('Error in uploadImageFile:', error);
    return res.status(500).json({ error: 'Gagal mengunggah media' });
  }
};


