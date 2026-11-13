import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrasaPontoApp());
}

class BrasaPontoApp extends StatelessWidget {
  const BrasaPontoApp({super.key});

  static const ink = Color(0xFF211A18);
  static const ember = Color(0xFFC93425);
  static const gold = Color(0xFFF6B73C);
  static const cream = Color(0xFFFFF8EF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brasa & Ponto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
            seedColor: ember, primary: ember, secondary: gold, surface: cream),
        fontFamily: 'DM Sans',
        appBarTheme: const AppBarTheme(
            backgroundColor: cream, foregroundColor: ink, elevation: 0),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontWeight: FontWeight.w800, color: ink, letterSpacing: -1.3),
          headlineMedium: TextStyle(
              fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.8),
          titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
          titleMedium: TextStyle(fontWeight: FontWeight.w700, color: ink),
          bodyLarge: TextStyle(color: ink),
          bodyMedium: TextStyle(color: Color(0xFF756B64)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.black.withValues(alpha: .06))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ember, width: 1.5)),
        ),
      ),
      home: const HomePage(),
    );
  }
}
