import 'package:flutter/material.dart';

/// Colors matching the Leaf Notes brand: forest green text, bright leaf
/// green accents, soft mint backgrounds. Used everywhere instead of
/// hard-coded colors so the look stays consistent.
class AppTheme {
  static const Color forest = Color(0xFF1A432B);
  static const Color leafLight = Color(0xFF4CAF50);
  static const Color leafDark = Color(0xFF2E7D32);
  static const Color mint = Color(0xFFE8F5E9);
  static const Color mintDark = Color(0xFFC8E6C9);
  static const Color offWhite = Color(0xFFFCFCFC);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: offWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: leafLight,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: offWhite,
        foregroundColor: forest,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: leafLight,
        brightness: Brightness.dark,
      ),
    );
  }
}
