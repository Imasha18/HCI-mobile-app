import 'package:flutter/foundation.dart';

class ApiConfig {
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '465451848829-5keopsu5c31fn3rc8t672sdqev28dgq4.apps.googleusercontent.com',
  );

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
