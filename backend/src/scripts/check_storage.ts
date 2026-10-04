import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();

async function main() {
  try {
    const rls: any = await prisma.$queryRawUnsafe(`
      SELECT relname, relrowsecurity 
      FROM pg_class 
      JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace 
      WHERE nspname = 'storage' AND relname IN ('objects', 'buckets');
    `);
    console.log('RLS status:', rls);
  } catch (e: any) {
    console.log('Error checking RLS:', e.message);
  }
}

main().finally(() => prisma.$disconnect());
