import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Brand
  static const Color brand = Color(0xFF7C3AED);
  static const Color brandLight = Color(0xFF9B5CF6);

  // Diff colors — dark
  static const Color addedBgDark = Color(0xFF0D2A1A);
  static const Color removedBgDark = Color(0xFF2A0D0D);
  static const Color addedFgDark = Color(0xFF3FB950);
  static const Color removedFgDark = Color(0xFFF85149);
  static const Color addedInlineDark = Color(0xFF1A4A2A);
  static const Color removedInlineDark = Color(0xFF4A1A1A);

  // Diff colors — light
  static const Color addedBgLight = Color(0xFFE6FFEC);
  static const Color removedBgLight = Color(0xFFFFEBEB);
  static const Color addedFgLight = Color(0xFF1A7F37);
  static const Color removedFgLight = Color(0xFFCF222E);
  static const Color addedInlineLight = Color(0xFFACF2BD);
  static const Color removedInlineLight = Color(0xFFFFBDBD);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.dark,
        surface: const Color(0xFF161B22),
      ).copyWith(
        surface: const Color(0xFF161B22),
        surfaceContainerHighest: const Color(0xFF21262D),
        outline: const Color(0xFF30363D),
        outlineVariant: const Color(0xFF21262D),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF30363D),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF161B22),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF6F8FA),
        outline: const Color(0xFFD0D7DE),
        outlineVariant: const Color(0xFFEAEEF2),
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD0D7DE),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
