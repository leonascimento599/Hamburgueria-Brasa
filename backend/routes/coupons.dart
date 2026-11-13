import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(body: {
    'coupons': [
      {'code': 'BRASA10', 'description': '10% de desconto no pedido'},
    ],
  });
}
