import fs from 'fs';
import path from 'path';
import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import { uploadBufferToSupabase, STORAGE_BUCKET } from '../config/supabase';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  console.log('--- Memulai Migrasi Uploads ke Supabase Storage ---');
  const uploadsDir = path.resolve(__dirname, '../../uploads');

  if (!fs.existsSync(uploadsDir)) {
    console.log('Direktori uploads lokal tidak ditemukan.');
    return;
  }

  const files = fs.readdirSync(uploadsDir).filter(file => !file.startsWith('.'));
  console.log(`Ditemukan ${files.length} file lokal di uploads:`, files);

  for (const filename of files) {
    const filePath = path.join(uploadsDir, filename);
    const buffer = fs.readFileSync(filePath);
    const ext = filename.split('.').pop()?.toLowerCase() || 'jpg';
    const mimeType = ext === 'jpg' || ext === 'jpeg' ? 'image/jpeg' : `image/${ext}`;

    console.log(`Mengunggah ${filename} ke bucket ${STORAGE_BUCKET}...`);
    const result = await uploadBufferToSupabase(filename, buffer, mimeType);

    if (result.success && result.url) {
      console.log(`Berhasil diunggah: ${result.url}`);

      // Update database records that reference this filename or /uploads/${filename}
      const oldSubstrings = [`/uploads/${filename}`, filename];

      for (const sub of oldSubstrings) {
        // 1. User avatarUrl
        const users = await prisma.user.findMany({
          where: { avatarUrl: { contains: sub } }
        });
        for (const u of users) {
          await prisma.user.update({
            where: { id: u.id },
            data: { avatarUrl: result.url }
          });
          console.log(`Updated user avatar for ${u.name} (${u.phoneNumber})`);
        }

        // 2. UserPhoto url
        const photos = await prisma.userPhoto.findMany({
          where: { url: { contains: sub } }
        });
        for (const p of photos) {
          await prisma.userPhoto.update({
            where: { id: p.id },
            data: { url: result.url }
          });
          console.log(`Updated UserPhoto ${p.id}`);
        }

        // 3. Message mediaUrl
        const messages = await prisma.message.findMany({
          where: { mediaUrl: { contains: sub } }
        });
        for (const m of messages) {
          await prisma.message.update({
            where: { id: m.id },
            data: { mediaUrl: result.url }
          });
          console.log(`Updated message ${m.id}`);
        }

        // 4. Story mediaUrl
        const stories = await prisma.story.findMany({
          where: { mediaUrl: { contains: sub } }
        });
        for (const s of stories) {
          await prisma.story.update({
            where: { id: s.id },
            data: { mediaUrl: result.url }
          });
          console.log(`Updated story ${s.id}`);
        }
      }
    } else {
      console.error(`Gagal mengunggah ${filename}:`, result.error);
    }
  }

  console.log('--- Migrasi selesai! ---');
}

main().finally(() => prisma.$disconnect());
