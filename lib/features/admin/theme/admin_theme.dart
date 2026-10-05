import 'package:flutter/material.dart';

class AdminTheme {
  // Brand Colors
  static const Color primary = Color(0xFFFF9800); // HomeBite Orange
  static const Color primaryDark = Color(0xFFF57C00);
  static const Color primaryLight = Color(0xFFFFF3E0);
  static const Color secondary = Color(0xFF263238);

  // Backgrounds & Surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F9FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEEEEEE);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Status Colors
  static const Color statusApproved = Color(0xFF2E7D32); // Green
  static const Color statusApprovedBg = Color(0xFFE8F5E9);

  static const Color statusPending = Color(0xFFFF9800); // Orange
  static const Color statusPendingBg = Color(0xFFFFF3E0);

  static const Color statusRejected = Color(0xFFD32F2F); // Red
  static const Color statusRejectedBg = Color(0xFFFFEBEE);

  static const Color statusActive = Color(0xFF1976D2); // Blue
  static const Color statusActiveBg = Color(0xFFE3F2FD);

  // Shadows & Decorations
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? cardBg,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: border ?? Border.all(color: AdminTheme.border),
      boxShadow: cardShadow,
    );
  }

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}
