import { createClient, SupabaseClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://dvhzjzssftmfctoccdrc.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY || '';
export const STORAGE_BUCKET = process.env.SUPABASE_STORAGE_BUCKET || 'chat-media';

let supabaseClient: SupabaseClient | null = null;

export const getSupabaseClient = (): SupabaseClient | null => {
  if (!SUPABASE_KEY) {
    return null;
  }
  if (!supabaseClient) {
    supabaseClient = createClient(SUPABASE_URL, SUPABASE_KEY, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  }
  return supabaseClient;
};

/**
 * Upload a binary buffer to Supabase Storage and return its public URL
 */
export const uploadBufferToSupabase = async (
  filename: string,
  buffer: Buffer,
  contentType: string = 'image/jpeg'
): Promise<{ success: boolean; url: string; error?: string }> => {
  const supabase = getSupabaseClient();
  if (!supabase) {
    return { success: false, url: '', error: 'Supabase API key belum dikonfigurasi di .env' };
  }

  try {
    const { data, error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(filename, buffer, {
        contentType,
        upsert: true,
      });

    if (error) {
      console.error('Supabase upload error:', error);
      return { success: false, url: '', error: error.message };
    }

    const { data: publicUrlData } = supabase.storage
      .from(STORAGE_BUCKET)
      .getPublicUrl(filename);

    return {
      success: true,
      url: publicUrlData.publicUrl,
    };
  } catch (err: any) {
    console.error('Supabase upload exception:', err);
    return { success: false, url: '', error: err.message };
  }
};

/**
 * Delete a file from Supabase Storage
 */
export const deleteFromSupabase = async (filename: string): Promise<boolean> => {
  const supabase = getSupabaseClient();
  if (!supabase) return false;

  try {
    const { error } = await supabase.storage.from(STORAGE_BUCKET).remove([filename]);
    return !error;
  } catch {
    return false;
  }
};
