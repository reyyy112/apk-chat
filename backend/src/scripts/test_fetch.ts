async function test() {
  const url = 'https://dvhzjzssftmfctoccdrc.supabase.co/storage/v1/bucket';
  try {
    const res = await fetch(url);
    console.log('Status without key:', res.status, await res.text());
  } catch (e: any) {
    console.log('Fetch error:', e.message);
  }
}
test();
