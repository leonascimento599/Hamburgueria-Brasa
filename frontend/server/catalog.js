import { supabaseRequest } from './supabase.js';

async function activeRows(table) {
  const query = { select: 'data', active: 'eq.true', order: 'position.asc' };
  const rows = await supabaseRequest(table, { query });
  return rows.map(row => row.data);
}

export function loadCoupons() {
  return activeRows('catalog_coupons');
}

export async function loadMenu() {
  const [categories, products, addOns, coupons] = await Promise.all([
    activeRows('catalog_categories'),
    activeRows('catalog_products'),
    activeRows('catalog_add_ons'),
    loadCoupons(),
  ]);
  return { categories: ['Todos', ...categories.map(row => row.name)], products, addOns, coupons };
}

export function getOnly(handler) {
  return async request => {
    const headers = { 'Cache-Control': 'no-store' };
    if (request.method !== 'GET') {
      return Response.json({ error: 'Método não permitido.' }, { status: 405, headers: { ...headers, Allow: 'GET' } });
    }
    try {
      return Response.json(await handler(), { headers });
    } catch (error) {
      console.error(error.message);
      return Response.json({ error: 'Catálogo indisponível no momento.' }, { status: 503, headers });
    }
  };
}
