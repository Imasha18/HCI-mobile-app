import 'package:flutter/foundation.dart';

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get resolvedBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  static const connectTimeout = Duration(seconds: 15);
}
