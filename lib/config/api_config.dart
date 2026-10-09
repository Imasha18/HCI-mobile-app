import 'package:flutter/foundation.dart';

class ApiConfig {
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '465451848829-5keopsu5c31fn3rc8t672sdqev28dgq4.apps.googleusercontent.com',
  );

  /// Override at build/run time, e.g. for a physical Android device:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000/api
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Backend port used when no explicit API_BASE_URL is provided.
  static const apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '5000',
  );

  static String get resolvedBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;

    // Flutter Web / Chrome: talk to the backend on the same machine the page
    // was served from, using the page's protocol (avoids mixed content).
    // Must be checked before defaultTargetPlatform, which can report
    // "android" in Chrome mobile emulation mode.
    if (kIsWeb) {
      final page = Uri.base;
      final host = page.host.isEmpty ? 'localhost' : page.host;
      final scheme = page.scheme == 'https' ? 'https' : 'http';
      return '$scheme://$host:$apiPort/api';
    }

    // Android emulator maps the host machine's localhost to 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$apiPort/api';
    }

    // iOS simulator, Windows, macOS, Linux desktop.
    return 'http://127.0.0.1:$apiPort/api';
  }

  static const connectTimeout = Duration(seconds: 15);
}
