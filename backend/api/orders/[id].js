import { orderResponse, storedOrders, tracking } from '../../server/orders.js';

export default {
  async fetch(request) {
    if (request.method !== 'GET') {
      return orderResponse({ error: 'Use GET para consultar um pedido.' }, 405, { Allow: 'GET' });
    }
    const pathname = new URL(request.url).pathname.replace(/\/$/, '');
    const id = pathname.split('/').at(-1).toUpperCase();
    if (!/^BP-(?:[A-F0-9]{6}|[A-F0-9]{16})$/.test(id)) {
      return orderResponse({ error: 'Pedido não encontrado.' }, 404);
    }
    try {
      const order = await storedOrders({ id });
      if (!order) return orderResponse({ error: 'Pedido não encontrado.' }, 404);
      return orderResponse(tracking(order));
    } catch (error) {
      console.error(error.name, error.cause?.code ?? '');
      return orderResponse({ error: 'Não foi possível consultar o pedido agora.' }, 503);
    }
  },
};
