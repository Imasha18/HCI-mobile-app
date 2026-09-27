import 'package:flutter/material.dart';

class AppTheme {
  static const _ink = Color(0xFF263238);
  static const _terracotta = Color(0xFFB85C38);
  static const _cream = Color(0xFFFFFBF5);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _terracotta,
      brightness: Brightness.light,
      surface: _cream,
    ),
    fontFamily: 'Georgia',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: _ink, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: _ink, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: _ink, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: _ink, height: 1.4),
      bodyMedium: TextStyle(color: Color(0xFF5F6668), height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
