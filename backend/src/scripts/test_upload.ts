import { uploadBufferToSupabase, STORAGE_BUCKET, getSupabaseClient } from '../config/supabase';

async function main() {
  console.log('Testing Supabase Storage upload...');
  const client = getSupabaseClient();
  if (!client) {
    console.error('Supabase client is null because SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY is not set in .env');
    return;
  }

  // Create a 1x1 transparent PNG buffer
  const samplePngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  const buffer = Buffer.from(samplePngBase64, 'base64');
  const filename = `test_upload_${Date.now()}.png`;

  console.log(`Uploading test file ${filename} to bucket ${STORAGE_BUCKET}...`);
  const res = await uploadBufferToSupabase(filename, buffer, 'image/png');
  console.log('Upload result:', res);

  if (res.success && res.url) {
    console.log('Verifying public accessibility via fetch...');
    try {
      const response = await fetch(res.url);
      console.log('HTTP GET Status:', response.status);
      if (response.ok) {
        console.log('SUCCESS! The file is publicly accessible at:', res.url);
      } else {
        console.warn('File uploaded but HTTP GET returned non-200:', response.status);
      }
    } catch (e: any) {
      console.error('Fetch error:', e.message);
    }
  }
}

main();
