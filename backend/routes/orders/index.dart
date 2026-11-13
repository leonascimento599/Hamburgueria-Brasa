import 'package:dart_frog/dart_frog.dart';
import '../../lib/order_store.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Método não permitido. Use POST para criar um pedido.'},
      headers: {'Allow': 'POST'},
    );
  }

  try {
    final payload = await context.request.json();
    if (payload is! Map<String, dynamic>) {
      return Response.json(
          statusCode: 400, body: {'error': 'Corpo JSON inválido.'});
    }
    final name = payload['customerName'];
    final address = payload['address'];
    final payment = payload['paymentMethod'];
    final items = payload['items'];
    if (name is! String ||
        name.trim().length < 2 ||
        address is! String ||
        address.trim().length < 8 ||
        payment is! String ||
        !['Pix na entrega', 'Cartão na entrega', 'Dinheiro']
            .contains(payment) ||
        items is! List) {
      return Response.json(statusCode: 422, body: {
        'error': 'Confira nome, endereço, pagamento e itens do pedido.'
      });
    }
    final order = await OrderStore.instance.create(payload);
    return Response.json(statusCode: 201, body: order);
  } on OrderStorageException {
    return Response.json(
        statusCode: 503, body: {'error': 'Pedido indisponível no momento.'});
  } on FormatException catch (error) {
    return Response.json(statusCode: 422, body: {'error': error.message});
  } catch (_) {
    return Response.json(
        statusCode: 400,
        body: {'error': 'Não foi possível interpretar o pedido.'});
  }
}
