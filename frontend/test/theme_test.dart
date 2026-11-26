import 'package:brasa_ponto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Fake implements SharedPreferencesWithCache {
  final _values = <String, bool>{};

  @override
  Object? get(String key) => _values[key];

  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }
}

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('Alterna e lembra o tema em uma tela de largura $width',
        (tester) async {
      final size = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.binding.setSurfaceSize(size);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final platform = tester.platformDispatcher;
      platform.platformBrightnessTestValue = Brightness.light;
      addTearDown(platform.clearPlatformBrightnessTestValue);
      final prefs = _Preferences();
      final client = MockClient((_) async => http.Response(
          '{"products":[],"categories":["Todos"],"addOns":[],"coupons":[]}',
          200));
      addTearDown(client.close);

      await http.runWithClient(() async {
        Future<void> openSite() async {
          await tester.pumpWidget(BrasaPontoApp(preferences: prefs));
          await tester.pumpAndSettle();
        }

        ThemeData currentTheme() =>
            Theme.of(tester.element(find.byType(Scaffold)));

        await openSite();
        expect(currentTheme().brightness, Brightness.light);
        platform.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();
        expect(currentTheme().brightness, Brightness.dark);

        await tester.enterText(find.byType(TextField), 'batata');
        final light = find.byTooltip('Ativar modo claro');
        await tester.tap(light);
        await tester.pumpAndSettle();
        expect(currentTheme().brightness, Brightness.light);
        expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            'batata');

        await tester.pumpWidget(const SizedBox.shrink());
        await openSite();
        expect(currentTheme().brightness, Brightness.light);

        await tester.tap(find.byTooltip('Ativar modo escuro'));
        await tester.pumpAndSettle();
        expect(currentTheme().brightness, Brightness.dark);
        platform.platformBrightnessTestValue = Brightness.light;
        await tester.pumpWidget(const SizedBox.shrink());
        await openSite();
        final theme = currentTheme();
        expect(theme.brightness, Brightness.dark);
        expect(theme.scaffoldBackgroundColor.computeLuminance(), lessThan(.1));
        expect(theme.inputDecorationTheme.fillColor!.computeLuminance(),
            lessThan(.1));

        await tester.tap(
            width < 650 ? find.byTooltip('Sacola (0)') : find.text('Sacola'));
        await tester.pumpAndSettle();
        expect(find.text('Sua sacola está vazia.'), findsOneWidget);
        final sheet = find.ancestor(
            of: find.text('Sua sacola'), matching: find.byType(Container));
        expect(
            tester.widgetList<Container>(sheet).any((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color ==
                    theme.colorScheme.surfaceContainerLow),
            isTrue);
        expect(tester.takeException(), isNull);
      }, () => client);
    });
  }
}
