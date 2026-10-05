import 'package:flutter/material.dart';

class RiderTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF20C957);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color secondaryGreen = Color(0xFFE8FBEF);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFFFFFFF);

  // Currency
  static const String currency = 'Rs. ';

  // Text Colors
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textMuted = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Status Colors
  static const Color statusGreen = Color(0xFF20C957);
  static const Color statusGreenBg = Color(0xFFE8FBEF);
  static const Color statusBlue = Color(0xFF1565C0);
  static const Color statusBlueBg = Color(0xFFE3F2FD);
  static const Color statusOrange = Color(0xFFE65100);
  static const Color statusOrangeBg = Color(0xFFFFF3E0);
  static const Color statusPurple = Color(0xFF7B1FA2);
  static const Color statusPurpleBg = Color(0xFFF3E5F5);
  static const Color statusRed = Color(0xFFD32F2F);
  static const Color statusRedBg = Color(0xFFFFEBEE);

  // Elevation Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1F20C957),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return statusGreen;
      case 'ACCEPTED':
        return statusBlue;
      case 'PICKED_UP':
      case 'PICKED UP':
        return statusOrange;
      case 'IN_TRANSIT':
      case 'IN TRANSIT':
        return statusPurple;
      case 'DELIVERED':
      case 'COMPLETED':
        return statusGreen;
      case 'CANCELLED':
      case 'REJECTED':
        return statusRed;
      default:
        return textMuted;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return statusGreenBg;
      case 'ACCEPTED':
        return statusBlueBg;
      case 'PICKED_UP':
      case 'PICKED UP':
        return statusOrangeBg;
      case 'IN_TRANSIT':
      case 'IN TRANSIT':
        return statusPurpleBg;
      case 'DELIVERED':
      case 'COMPLETED':
        return statusGreenBg;
      case 'CANCELLED':
      case 'REJECTED':
        return statusRedBg;
      default:
        return surfaceLight;
    }
  }
}
