const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const publicUrl = 'https://tumor-oliver-interest-flickr.trycloudflare.com';

  const stories = await prisma.story.findMany();
  for (const s of stories) {
    if (s.mediaUrl && (s.mediaUrl.includes('localhost:3000') || s.mediaUrl.includes('127.0.0.1:3000'))) {
      const fixed = s.mediaUrl.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicUrl);
      await prisma.story.update({
        where: { id: s.id },
        data: { mediaUrl: fixed },
      });
      console.log(`Updated story ${s.id} mediaUrl to ${fixed}`);
    }
  }

  const users = await prisma.user.findMany();
  for (const u of users) {
    if (u.avatarUrl && (u.avatarUrl.includes('localhost:3000') || u.avatarUrl.includes('127.0.0.1:3000'))) {
      const fixed = u.avatarUrl.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicUrl);
      await prisma.user.update({
        where: { id: u.id },
        data: { avatarUrl: fixed },
      });
      console.log(`Updated user ${u.name} avatarUrl to ${fixed}`);
    }
  }

  const photos = await prisma.userPhoto.findMany();
  for (const p of photos) {
    if (p.url && (p.url.includes('localhost:3000') || p.url.includes('127.0.0.1:3000'))) {
      const fixed = p.url.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicUrl);
      await prisma.userPhoto.update({
        where: { id: p.id },
        data: { url: fixed },
      });
      console.log(`Updated userPhoto ${p.id} url to ${fixed}`);
    }
  }

  const messages = await prisma.message.findMany({ where: { mediaUrl: { not: null } } });
  for (const m of messages) {
    if (m.mediaUrl && (m.mediaUrl.includes('localhost:3000') || m.mediaUrl.includes('127.0.0.1:3000'))) {
      const fixed = m.mediaUrl.replace(/https?:\/\/(localhost|127\.0\.0\.1):3000/, publicUrl);
      await prisma.message.update({
        where: { id: m.id },
        data: { mediaUrl: fixed },
      });
      console.log(`Updated message ${m.id} mediaUrl to ${fixed}`);
    }
  }
}

main().then(() => prisma.$disconnect());
