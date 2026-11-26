import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const charcoal = Color(0xFF211A18);
  static const ember = Color(0xFFC93425);
  static const gold = Color(0xFFF6B73C);

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: ember,
      brightness: brightness,
      primary: dark ? const Color(0xFFFF9B83) : ember,
      onPrimary: dark ? const Color(0xFF401309) : Colors.white,
      primaryContainer:
          dark ? const Color(0xFF543028) : const Color(0xFFFFE3D8),
      onPrimaryContainer:
          dark ? const Color(0xFFFFC5B6) : const Color(0xFF6C2117),
      secondary: gold,
      onSecondary: charcoal,
      secondaryContainer:
          dark ? const Color(0xFF392B24) : const Color(0xFFFFE9D7),
      onSecondaryContainer: dark ? const Color(0xFFF8E7DA) : charcoal,
      tertiary: dark ? const Color(0xFF89D8A7) : const Color(0xFF197144),
      surface: dark ? const Color(0xFF191513) : const Color(0xFFFFF8EF),
      surfaceContainerLow:
          dark ? const Color(0xFF231E1B) : const Color(0xFFFFFCF7),
      surfaceContainer: dark ? const Color(0xFF2B2522) : Colors.white,
      surfaceContainerHigh:
          dark ? const Color(0xFF382F2A) : const Color(0xFFF4EDE5),
      surfaceContainerHighest:
          dark ? const Color(0xFF43372F) : const Color(0xFFE9D9C8),
      onSurface: dark ? const Color(0xFFF8EDE5) : charcoal,
      onSurfaceVariant:
          dark ? const Color(0xFFCABBB0) : const Color(0xFF756B64),
      outlineVariant: dark ? const Color(0xFF594B43) : const Color(0xFFEDE3D8),
      inverseSurface: dark ? const Color(0xFFF1DFD1) : charcoal,
      onInverseSurface: dark ? charcoal : Colors.white,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      fontFamily: 'DM Sans',
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
            letterSpacing: -1.3),
        headlineMedium: TextStyle(
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
            letterSpacing: -0.8),
        titleLarge:
            TextStyle(fontWeight: FontWeight.w800, color: colors.onSurface),
        titleMedium:
            TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface),
        bodyLarge: TextStyle(color: colors.onSurface),
        bodyMedium: TextStyle(color: colors.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.surfaceContainerLow),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: inputBorder,
        enabledBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: colors.outlineVariant)),
        focusedBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }
}
