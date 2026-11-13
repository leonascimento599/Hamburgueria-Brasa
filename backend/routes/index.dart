import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(body: {
    'name': 'Brasa & Ponto API',
    'status': 'ok',
    'version': '1.0.0',
    'endpoints': {
      'GET /menu': 'Cardápio, categorias, adicionais e cupons',
      'GET /coupons': 'Ofertas disponíveis',
      'POST /orders': 'Criar pedido',
      'GET /orders/:id': 'Consultar status de um pedido',
    },
  });
}
