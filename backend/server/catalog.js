import { supabaseRequest } from './supabase.js';

const burgerAddOns = ['extra-burger', 'cheddar', 'bacon', 'queijo', 'cebola', 'ovo', 'molho'];
const defaultAddOns = {
  'brasa-classico': burgerAddOns,
  'duplo-defumado': burgerAddOns,
  'cheddar-crocante': burgerAddOns,
  'frango-crocante': ['cheddar', 'bacon', 'queijo', 'cebola', 'ovo', 'molho'],
  'combo-brasa': burgerAddOns,
  'combo-duplo': burgerAddOns,
  'fritas-rusticas': ['cheddar', 'bacon', 'molho'],
  'onion-rings': ['molho'],
  'frango-frito': ['molho'],
};

function availableAddOnIds(product, activeIds) {
  const allowed = product.allowedAddOnIds === undefined
    ? defaultAddOns[product.id] ?? []
    : product.allowedAddOnIds;
  if (!Array.isArray(allowed)) return [];
  return [...new Set(allowed.filter(id => activeIds.has(id)))];
}

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
  const activeIds = new Set(addOns.map(extra => extra.id));
  return {
    categories: ['Todos', ...categories.map(row => row.name)],
    products: products.map(product => ({
      ...product,
      allowedAddOnIds: availableAddOnIds(product, activeIds),
    })),
    addOns,
    coupons,
  };
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
