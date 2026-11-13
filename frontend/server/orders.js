import { randomBytes } from 'node:crypto';
import { supabaseRequest } from './supabase.js';



const payments = ['Pix na entrega', 'Cartão na entrega', 'Dinheiro'];
const cents = value => Math.round(value * 100);

export class InvalidOrder extends Error {}

export function calculateOrder(input, menu) {
  const products = new Map(menu.products.map(product => [product.id, product]));
  const extras = new Map(menu.addOns.map(extra => [extra.id, extra]));
  const { customerName, address, paymentMethod, items, coupon } = input ?? {};
  if (typeof customerName !== 'string' || customerName.trim().length < 2 ||
      typeof address !== 'string' || address.trim().length < 8 ||
      !payments.includes(paymentMethod) || !Array.isArray(items) || !items.length) {
    throw new InvalidOrder('Confira nome, endereço, pagamento e itens do pedido.');
  }
  const appliedCoupon = menu.coupons.find(entry => entry.code === coupon);
  if (coupon != null && coupon !== '' && !appliedCoupon) {
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

  const discountPercent = appliedCoupon?.discountPercent ?? 0;
  if (typeof discountPercent !== 'number' || !Number.isFinite(discountPercent) ||
      discountPercent < 0 || discountPercent > 100) {
    throw new Error('Percentual do cupom inválido no catálogo.');
  }
  const discount = Math.round(subtotal * discountPercent / 100);
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
  if (order) {
    await supabaseRequest('orders', { body: { id: order.id, payload: order } });
    return;
  }
  const rows = await supabaseRequest('orders', { query: { id: 'eq.' + id, select: 'payload' } });
  return rows[0]?.payload ?? null;
}

export function orderResponse(body, status = 200, headers = {}) {
  return Response.json(body, { status, headers: { ...headers, 'Cache-Control': 'no-store' } });
}
