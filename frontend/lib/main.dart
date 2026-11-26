import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'screens/home_page.dart';

const _darkModeKey = 'brasa.darkMode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesWithCache? preferences;
  try {
    preferences = await SharedPreferencesWithCache.create(
      cacheOptions:
          const SharedPreferencesWithCacheOptions(allowList: {_darkModeKey}),
    );
  } catch (_) {
    // O navegador pode bloquear o armazenamento local.
  }
  runApp(BrasaPontoApp(preferences: preferences));
}

class BrasaPontoApp extends StatefulWidget {
  const BrasaPontoApp({super.key, this.preferences});

  final SharedPreferencesWithCache? preferences;

  @override
  State<BrasaPontoApp> createState() => _BrasaPontoAppState();
}

class _BrasaPontoAppState extends State<BrasaPontoApp> {
  late ThemeMode _themeMode = switch (widget.preferences?.get(_darkModeKey)) {
    true => ThemeMode.dark,
    false => ThemeMode.light,
    _ => ThemeMode.system,
  };

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _themeMode = enabled ? ThemeMode.dark : ThemeMode.light);
    try {
      await widget.preferences?.setBool(_darkModeKey, enabled);
    } catch (_) {
      // A escolha continua valendo nesta visita se não for possível salvá-la.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brasa & Ponto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: HomePage(onDarkModeChanged: _setDarkMode),
    );
  }
}
