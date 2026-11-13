import { randomBytes } from 'node:crypto';
import { menu } from './catalog.js';

const products = new Map(menu.products.map(product => [product.id, product]));
const extras = new Map(menu.addOns.map(extra => [extra.id, extra]));
const payments = ['Pix na entrega', 'Cartão na entrega', 'Dinheiro'];
const cents = value => Math.round(value * 100);

export class InvalidOrder extends Error {}

export function calculateOrder(input) {
  const { customerName, address, paymentMethod, items, coupon } = input ?? {};
  if (typeof customerName !== 'string' || customerName.trim().length < 2 ||
      typeof address !== 'string' || address.trim().length < 8 ||
      !payments.includes(paymentMethod) || !Array.isArray(items) || !items.length) {
    throw new InvalidOrder('Confira nome, endereço, pagamento e itens do pedido.');
  }
  if (coupon != null && coupon !== '' && coupon !== 'BRASA10') {
    throw new InvalidOrder('Cupom inválido ou indisponível.');
  }

  let subtotal = 0;
  const calculatedItems = items.map(item => {
    const product = products.get(item?.productId);
    const quantity = item?.quantity;
    if (!product || !Number.isInteger(quantity) || quantity < 1 || quantity > 20) {
      throw new InvalidOrder('Produto ou quantidade inválida.');
    }
    if (!Array.isArray(item.extras)) throw new InvalidOrder('Adicionais inválidos.');
    const selectedExtras = item.extras.map(id => {
      const extra = extras.get(id);
      if (!extra) throw new InvalidOrder('Adicional não encontrado.');
      return extra;
    });
    const unitPrice = selectedExtras.reduce((sum, extra) => sum + cents(extra.price), cents(product.price));
    const total = unitPrice * quantity;
    subtotal += total;
    return {
      productId: product.id,
      name: product.name,
      quantity,
      extras: selectedExtras,
      removedIngredients: Array.isArray(item.removedIngredients) ? item.removedIngredients : [],
      unitPrice: unitPrice / 100,
      total: total / 100,
    };
  });

  const discount = coupon === 'BRASA10' ? Math.round(subtotal / 10) : 0;
  const deliveryFee = subtotal >= 6500 ? 0 : 690;
  return {
    id: 'BP-' + randomBytes(8).toString('hex').toUpperCase(),
    customerName: customerName.trim(),
    address: address.trim(),
    paymentMethod,
    items: calculatedItems,
    coupon: coupon ?? null,
    subtotal: subtotal / 100,
    discount: discount / 100,
    deliveryFee: deliveryFee / 100,
    total: (subtotal - discount + deliveryFee) / 100,
    createdAt: new Date().toISOString(),
  };
}

export function tracking(order) {
  const elapsed = Math.max(0, (Date.now() - Date.parse(order.createdAt)) / 1000);
  const statusIndex = [15, 60, 110].filter(limit => elapsed >= limit).length;
  const labels = ['Pedido recebido', 'Preparando', 'Saiu para entrega', 'Entregue'];
  return {
    id: order.id,
    statusIndex,
    status: statusIndex === 1 ? 'Preparando seu pedido' : labels[statusIndex],
    etaMinutes: Math.max(0, 2 - Math.floor(elapsed / 60)),
    timeline: labels.map((label, index) => ({ label, done: index <= statusIndex })),
  };
}

export async function storedOrders({ order, id }) {
  const base = process.env.SUPABASE_URL?.trim();
  const key = process.env.SUPABASE_SECRET_KEY?.trim();
  if (!base || !key) throw new Error('Variáveis do Supabase ausentes.');
  const url = new URL('/rest/v1/orders', base);
  if (url.protocol !== 'https:') throw new Error('A URL do Supabase deve usar HTTPS.');
  const headers = { apikey: key };
  if (order) {
    headers['Content-Type'] = 'application/json';
    headers.Prefer = 'return=minimal';
  } else {
    url.searchParams.set('id', 'eq.' + id);
    url.searchParams.set('select', 'payload');
  }
  const response = await fetch(url, {
    method: order ? 'POST' : 'GET',
    headers,
    body: order ? JSON.stringify({ id: order.id, payload: order }) : undefined,
    signal: AbortSignal.timeout(6500),
    redirect: 'error',
  });
  if (response.status !== (order ? 201 : 200)) {
    throw new Error('Supabase /orders: HTTP ' + response.status);
  }
  if (!order) {
    const rows = await response.json();
    return rows[0]?.payload ?? null;
  }
}

export function orderResponse(body, status = 200, headers = {}) {
  return Response.json(body, { status, headers: { ...headers, 'Cache-Control': 'no-store' } });
}
