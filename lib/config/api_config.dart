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
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api'
        : 'http://localhost:5000/api';
  }

  static String get serverOrigin {
    final base = resolvedBaseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static const connectTimeout = Duration(seconds: 15);
}
