import 'package:flutter/material.dart';

class CookTheme {
  // Brand Colors
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryDark = Color(0xFFF57C00);
  static const Color secondaryOrange = Color(0xFFFFF3E0);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFFFFFFF);

  // Currency
  static const String currency = 'Rs. ';

  // Text Colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Status Colors
  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusYellow = Color(0xFFE65100);
  static const Color statusYellowBg = Color(0xFFFFF8E1);
  static const Color statusRed = Color(0xFFC62828);
  static const Color statusRedBg = Color(0xFFFFEBEE);
  static const Color statusBlue = Color(0xFF1565C0);
  static const Color statusBlueBg = Color(0xFFE3F2FD);

  // Soft Elevation Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x18FF9800),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // Helper for status badge colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
      case 'ready for pickup':
      case 'ready':
        return statusGreen;
      case 'preparing':
      case 'in preparation':
        return statusYellow;
      case 'rejected':
      case 'cancelled':
        return statusRed;
      default:
        return primaryDark;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
      case 'ready for pickup':
      case 'ready':
        return statusGreenBg;
      case 'preparing':
      case 'in preparation':
        return statusYellowBg;
      case 'rejected':
      case 'cancelled':
        return statusRedBg;
      default:
        return secondaryOrange;
    }
  }
}
