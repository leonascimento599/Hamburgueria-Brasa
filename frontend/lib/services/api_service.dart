import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static Future<List<Product>> fetchMenu() async {
    final response = await http.get(Uri.parse('$baseUrl/menu')).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar o cardápio (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['products'] as List<dynamic>)
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String address,
    required String paymentMethod,
    required List<CartLine> items,
    required String? coupon,
  }) async {
    final payload = {
      'customerName': customerName,
      'address': address,
      'paymentMethod': paymentMethod,
      'coupon': coupon,
      'items': items.map((line) => {
        'productId': line.product.id,
        'quantity': line.quantity,
        'extras': line.extras.map((extra) => extra.id).toList(),
        'removedIngredients': line.removedIngredients,
      }).toList(),
    };
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(body['error'] ?? 'Não foi possível finalizar o pedido.');
    }
    return body;
  }

  static Future<Map<String, dynamic>> trackOrder(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Pedido não encontrado.');
    }
    return body;
  }
}
