import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../config/app_routes.dart';
import '../../../core/utils/navigator_key.dart';
import '../../../services/api_client.dart';

class AdminSessionManager {
  static final AdminSessionManager _instance = AdminSessionManager._internal();
  factory AdminSessionManager() => _instance;
  AdminSessionManager._internal();

  static const Duration inactivityTimeout = Duration(hours: 2);
  static const String lastActivityKey = 'admin_last_activity';
  static const String timeoutMessage =
      'Your admin session expired due to inactivity. Please log in again.';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _timer;
  bool _isActive = false;

  bool get isActive => _isActive;

  Future<void> startSession() async {
    _isActive = true;
    await recordActivity();
  }

  Future<void> recordActivity() async {
    if (!_isActive) {
      _isActive = true;
    }
    _timer?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    await _storage.write(key: lastActivityKey, value: now.toString());

    _timer = Timer(inactivityTimeout, () {
      handleTimeout();
    });
  }

  Future<bool> isSessionExpired() async {
    final lastActivityStr = await _storage.read(key: lastActivityKey);
    if (lastActivityStr == null) {
      return false;
    }
    final lastActivityMs = int.tryParse(lastActivityStr);
    if (lastActivityMs == null) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastActivityMs) >= inactivityTimeout.inMilliseconds;
  }

  Future<void> stopSession() async {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    await _storage.delete(key: lastActivityKey);
  }

  Future<void> handleTimeout() async {
    await stopSession();
    await _storage.delete(key: 'auth_token');
    ApiClient().clearCache();

    final messenger = appScaffoldMessengerKey.currentState;
    messenger?.removeCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(timeoutMessage),
        backgroundColor: Color(0xFFD32F2F),
        duration: Duration(seconds: 4),
      ),
    );

    final navigator = appNavigatorKey.currentState;
    navigator?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
