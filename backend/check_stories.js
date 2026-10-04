const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const userId = '28d9762e-c641-4103-ad57-6efa78feed2e';
  const contacts = await prisma.contact.findMany({
    where: {
      OR: [
        { userId },
        { targetUserId: userId },
      ],
    },
    select: {
      userId: true,
      targetUserId: true,
    },
  });
  console.log('contacts for zaki:', contacts);
  const allowedUserIdsSet = new Set();
  allowedUserIdsSet.add(userId);
  contacts.forEach((c) => {
    allowedUserIdsSet.add(c.userId);
    allowedUserIdsSet.add(c.targetUserId);
  });
  console.log('allowedUserIdsSet:', Array.from(allowedUserIdsSet));

  const stories = await prisma.story.findMany({
    where: {
      userId: { in: Array.from(allowedUserIdsSet) },
      expiresAt: { gt: new Date() },
    }
  });
  console.log('stories found:', stories);
}

main().then(() => prisma.$disconnect());
