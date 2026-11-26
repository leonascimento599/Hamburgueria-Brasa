import 'dart:convert';

import 'package:brasa_ponto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final size in [const Size(1200, 900), const Size(600, 844)]) {
    testWidgets('Continua comprando com a sacola em $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var submittedOrders = 0;
      final client = MockClient((request) async {
        if (request.method == 'POST') submittedOrders++;
        return http.Response(
            jsonEncode({
              'products': [
                for (final id in ['a', 'b'])
                  {
                    'id': id,
                    'name': 'Produto $id',
                    'category': 'Sobremesas',
                    'description': 'Produto de teste',
                    'price': 10,
                    'image': 'https://example.com/image.jpg',
                    'allowedAddOnIds': [],
                  },
              ],
              'categories': ['Todos', 'Sobremesas'],
              'addOns': [],
              'coupons': [],
            }),
            200);
      });
      addTearDown(client.close);

      await http.runWithClient(() async {
        await tester.pumpWidget(const BrasaPontoApp());
        await tester.pumpAndSettle();

        Future<void> addProduct(String name) async {
          final card = find.ancestor(
            of: find.text(name),
            matching: find.byWidgetPredicate(
                (widget) => widget.runtimeType.toString() == '_ProductCard'),
          );
          final button =
              find.descendant(of: card, matching: find.text('Personalizar'));
          await tester.scrollUntilVisible(button, 150,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining('Adicionar •'));
          await tester.pumpAndSettle();
        }

        await addProduct('Produto a');
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(
            tester.getSize(find.byWidget(scaffold.bottomNavigationBar!)).height,
            lessThan(150));
        await tester.tap(find.textContaining('Ver sacola (1)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuar comprando'));
        await tester.pumpAndSettle();
        expect(find.text('Sua sacola'), findsNothing);

        await addProduct('Produto b');
        await tester.tap(find.textContaining('Ver sacola (2)'));
        await tester.pumpAndSettle();
        expect(find.text('Produto a'), findsWidgets);
        expect(find.text('Produto b'), findsWidgets);
        expect(submittedOrders, 0);
        expect(tester.takeException(), isNull);
      }, () => client);
    });
  }
}
