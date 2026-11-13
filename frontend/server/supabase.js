export async function supabaseRequest(table, { query, body } = {}) {
  const base = process.env.SUPABASE_URL?.trim();
  const key = process.env.SUPABASE_SECRET_KEY?.trim();
  if (!base || !key) throw new Error('Variáveis do Supabase ausentes.');
  const url = new URL('/rest/v1/' + table, base);
  if (url.protocol !== 'https:') throw new Error('A URL do Supabase deve usar HTTPS.');
  url.search = new URLSearchParams(query);
  const headers = { apikey: key };
  if (body) {
    headers['Content-Type'] = 'application/json';
    headers.Prefer = 'return=minimal';
  }
  const response = await fetch(url, {
    method: body ? 'POST' : 'GET',
    headers,
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(6500),
    redirect: 'error',
  });
  if (response.status !== (body ? 201 : 200)) {
    throw new Error('Supabase ' + table + ': HTTP ' + response.status);
  }
  if (!body) return response.json();
}
