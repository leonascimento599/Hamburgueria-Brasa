import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'menu_data.dart';

class OrderStore {
  OrderStore._();
  static final OrderStore instance = OrderStore._();

  final HttpClient _client = HttpClient();

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final customerName = (payload['customerName'] as String).trim();
    final address = (payload['address'] as String).trim();
    final paymentMethod = payload['paymentMethod'] as String;
    final items = payload['items'] as List<dynamic>;
    final extrasById = {
      for (final extra in addOns) extra['id'] as String: extra
    };
    final productsById = {
      for (final product in products) product['id'] as String: product
    };

    final calculatedItems = <Map<String, dynamic>>[];
    var subtotal = 0.0;
    for (final rawItem in items) {
      if (rawItem is! Map)
        throw const FormatException('Item do pedido inválido.');
      final productId = rawItem['productId'];
      final quantity = rawItem['quantity'];
      if (productId is! String ||
          quantity is! int ||
          quantity < 1 ||
          quantity > 20) {
        throw const FormatException('Produto ou quantidade inválida.');
      }
      final product = productsById[productId];
      if (product == null)
        throw const FormatException('Produto não encontrado no cardápio.');
      final extrasRaw = rawItem['extras'];
      if (extrasRaw is! List)
        throw const FormatException('Adicionais inválidos.');
      final selectedExtras = <Map<String, dynamic>>[];
      var extrasPrice = 0.0;
      for (final extraId in extrasRaw) {
        if (extraId is! String || !extrasById.containsKey(extraId)) {
          throw const FormatException('Adicional não encontrado.');
        }
        final extra = extrasById[extraId]!;
        selectedExtras.add(extra);
        extrasPrice += (extra['price'] as num).toDouble();
      }
      final unitPrice = (product['price'] as num).toDouble() + extrasPrice;
      final lineTotal = unitPrice * quantity;
      subtotal += lineTotal;
      calculatedItems.add({
        'productId': productId,
        'name': product['name'],
        'quantity': quantity,
        'extras': selectedExtras,
        'removedIngredients': rawItem['removedIngredients'] is List
            ? rawItem['removedIngredients']
            : <dynamic>[],
        'unitPrice': unitPrice,
        'total': lineTotal,
      });
    }

    if (calculatedItems.isEmpty)
      throw const FormatException('Adicione pelo menos um produto.');
    final coupon = payload['coupon'];
    if (coupon != null && coupon != '' && coupon != 'BRASA10') {
      throw const FormatException('Cupom inválido ou indisponível.');
    }
    final discount = coupon == 'BRASA10' ? subtotal * .10 : 0.0;
    final deliveryFee = subtotal >= 65 ? 0.0 : 6.90;
    final total = subtotal - discount + deliveryFee;
    final suffix = Random.secure()
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    final id = 'BP-$suffix';
    final now = DateTime.now().toUtc();

    final order = <String, dynamic>{
      'id': id,
      'customerName': customerName,
      'address': address,
      'paymentMethod': paymentMethod,
      'items': calculatedItems,
      'coupon': coupon,
      'subtotal': _roundMoney(subtotal),
      'discount': _roundMoney(discount),
      'deliveryFee': deliveryFee,
      'total': _roundMoney(total),
      'createdAt': now.toIso8601String(),
    };
    await _request('POST', body: {'id': id, 'payload': order});
    return statusFor(order);
  }

  Future<Object?> _request(String method,
      {Map<String, String>? query, Map<String, dynamic>? body}) async {
    final base =
        Uri.tryParse((Platform.environment['SUPABASE_URL'] ?? '').trim());
    final key = Platform.environment['SUPABASE_SECRET_KEY']?.trim();
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        key == null ||
        key.isEmpty) {
      stderr.writeln('Confira SUPABASE_URL e SUPABASE_SECRET_KEY.');
      throw const OrderStorageException();
    }
    try {
      const timeout = Duration(seconds: 10);
      final uri = base.replace(path: '/rest/v1/orders', queryParameters: query);
      final request = await _client.openUrl(method, uri).timeout(timeout);
      request.followRedirects = false;
      request.headers.set('apikey', key);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.headers.set('Prefer', 'return=minimal');
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      final text =
          await response.transform(utf8.decoder).join().timeout(timeout);
      if (response.statusCode != (body == null ? 200 : 201)) {
        stderr.writeln('Supabase /orders: HTTP ${response.statusCode}.');
        throw const OrderStorageException();
      }
      return body == null ? jsonDecode(text) : null;
    } on OrderStorageException {
      rethrow;
    } on Exception catch (error) {
      stderr.writeln('Supabase /orders: ${error.runtimeType}.');
      throw const OrderStorageException();
    }
  }

  Future<Map<String, dynamic>?> find(String id) async {
    final rows =
        await _request('GET', query: {'id': 'eq.$id', 'select': 'payload'});
    if (rows is! List) throw const OrderStorageException();
    if (rows.isEmpty) return null;
    final row = rows.first;
    if (row is! Map || row['payload'] is! Map<String, dynamic>) {
      throw const OrderStorageException();
    }
    return statusFor(row['payload'] as Map<String, dynamic>);
  }

  Map<String, dynamic> statusFor(Map<String, dynamic> order) {
    final createdAt = DateTime.parse(order['createdAt'] as String);
    final elapsed = DateTime.now().toUtc().difference(createdAt);
    final int index;
    final String status;
    if (elapsed.inSeconds < 15) {
      index = 0;
      status = 'Pedido recebido';
    } else if (elapsed.inSeconds < 60) {
      index = 1;
      status = 'Preparando seu pedido';
    } else if (elapsed.inSeconds < 110) {
      index = 2;
      status = 'Saiu para entrega';
    } else {
      index = 3;
      status = 'Entregue';
    }
    final eta = max(0, 2 - elapsed.inMinutes);
    return {
      ...order,
      'statusIndex': index,
      'status': status,
      'etaMinutes': eta,
      'timeline': [
        {'label': 'Pedido recebido', 'done': index >= 0},
        {'label': 'Preparando', 'done': index >= 1},
        {'label': 'Saiu para entrega', 'done': index >= 2},
        {'label': 'Entregue', 'done': index >= 3},
      ],
    };
  }

  double _roundMoney(double value) => (value * 100).roundToDouble() / 100;
}

class OrderStorageException implements Exception {
  const OrderStorageException();
}
