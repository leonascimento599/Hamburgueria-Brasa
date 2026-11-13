import { loadMenu } from '../../server/catalog.js';
import { calculateOrder, InvalidOrder, orderResponse, storedOrders, tracking } from '../../server/orders.js';

export default {
  async fetch(request) {
    if (request.method !== 'POST') {
      return orderResponse({ error: 'Use POST para criar um pedido.' }, 405, { Allow: 'POST' });
    }
    let payload;
    try {
      payload = await request.json();
    } catch {
      return orderResponse({ error: 'Corpo JSON inválido.' }, 400);
    }
    try {
      const order = calculateOrder(payload, await loadMenu());
      await storedOrders({ order });
      return orderResponse(tracking(order), 201);
    } catch (error) {
      if (error instanceof InvalidOrder) return orderResponse({ error: error.message }, 422);
      console.error(error.name, error.cause?.code ?? '');
      return orderResponse({ error: 'Não foi possível salvar o pedido agora.' }, 503);
    }
  },
};
