import 'package:dart_frog/dart_frog.dart';
import '../../lib/order_store.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'GET') {
    return Response.json(
      statusCode: 405,
      body: {
        'error': 'Método não permitido. Use GET para consultar um pedido.'
      },
      headers: {'Allow': 'GET'},
    );
  }
  try {
    final order = await OrderStore.instance.find(id.toUpperCase());
    if (order == null) {
      return Response.json(
          statusCode: 404, body: {'error': 'Pedido não encontrado.'});
    }
    return Response.json(body: order);
  } on OrderStorageException {
    return Response.json(
        statusCode: 503,
        body: {'error': 'Rastreamento indisponível no momento.'});
  }
}
