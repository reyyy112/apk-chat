import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();

async function main() {
  try {
    // 1. Ensure bucket exists and is public
    await prisma.$executeRawUnsafe(`
      INSERT INTO storage.buckets (id, name, public)
      VALUES ('chat-media', 'chat-media', true)
      ON CONFLICT (id) DO UPDATE SET public = true;
    `);
    console.log('Bucket chat-media ensured.');

    // 2. Add RLS policies for storage.objects
    await prisma.$executeRawUnsafe(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public Access for chat-media'
        ) THEN
          CREATE POLICY "Public Access for chat-media"
          ON storage.objects FOR SELECT
          USING (bucket_id = 'chat-media');
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow Uploads to chat-media'
        ) THEN
          CREATE POLICY "Allow Uploads to chat-media"
          ON storage.objects FOR INSERT
          WITH CHECK (bucket_id = 'chat-media');
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow Updates to chat-media'
        ) THEN
          CREATE POLICY "Allow Updates to chat-media"
          ON storage.objects FOR UPDATE
          USING (bucket_id = 'chat-media');
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow Deletes in chat-media'
        ) THEN
          CREATE POLICY "Allow Deletes in chat-media"
          ON storage.objects FOR DELETE
          USING (bucket_id = 'chat-media');
        END IF;
      END $$;
    `);
    console.log('Policies created or already exist.');

    const policies: any = await prisma.$queryRawUnsafe(`
      SELECT policyname, cmd, roles
      FROM pg_policies
      WHERE schemaname = 'storage'
    `);
    console.log('Current storage policies:', policies);
  } catch (e: any) {
    console.log('Error configuring storage policies:', e.message);
  }
}

main().finally(() => prisma.$disconnect());
