import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/api_config.dart';

/// Google credential to send to the HomeBite backend for verification.
///
/// Android/iOS provide an [idToken]. Flutter Web (Google Identity Services)
/// provides an [accessToken] instead. The backend verifies whichever one it
/// receives with Google, so the app never trusts the email/name locally.
class GoogleCredential {
  const GoogleCredential({this.idToken, this.accessToken});

  final String? idToken;
  final String? accessToken;

  Map<String, String> toJson() {
    final map = <String, String>{};
    if (idToken != null) map['idToken'] = idToken!;
    if (accessToken != null) map['accessToken'] = accessToken!;
    return map;
  }
}

/// A Google sign-in failure with a message that is safe to show to users.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  /// Web: the Web OAuth client ID is passed as `clientId` (this is what
  /// google_sign_in_web requires; `serverClientId` is not supported there).
  ///
  /// Android/iOS: the same Web client ID is passed as `serverClientId`, so the
  /// returned ID token's audience matches what the backend verifies against.
  /// The Android OAuth client itself is matched by package name + SHA-1 in
  /// Google Cloud, not by a value in code.
  late final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId: ApiConfig.googleClientId,
          scopes: const ['openid', 'email', 'profile'],
        )
      : GoogleSignIn(
          serverClientId: ApiConfig.googleClientId,
          scopes: const ['email', 'profile'],
        );

  /// Opens the Google account chooser.
  ///
  /// Returns `null` if the user cancelled. Throws [GoogleAuthException] with a
  /// user-friendly message for every other failure.
  ///
  /// Call this directly from the button's onPressed (no awaits before it) so
  /// browsers treat the popup as user-initiated and don't block it.
  Future<GoogleCredential?> signIn() async {
    if (ApiConfig.googleClientId.isEmpty) {
      _log('GOOGLE_CLIENT_ID is empty.');
      throw const GoogleAuthException(
        'Google Sign-In is currently unavailable. Please try again.',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // user closed the chooser

      final auth = await account.authentication;
      final credential = GoogleCredential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      if (credential.idToken == null && credential.accessToken == null) {
        _log('Google returned no idToken or accessToken.');
        throw const GoogleAuthException(
          'Google Sign-In is currently unavailable. Please try again.',
        );
      }
      return credential;
    } on GoogleAuthException {
      rethrow;
    } on PlatformException catch (error) {
      _log('PlatformException(${error.code}): ${error.message} ${error.details ?? ''}');
      if (_isCancel(error)) return null;
      throw GoogleAuthException(_messageFor(error));
    } catch (error, stack) {
      // e.g. AssertionError / misconfiguration in google_sign_in_web.
      _log('Unexpected Google sign-in error: $error\n$stack');
      throw const GoogleAuthException(
        'Google Sign-In is currently unavailable. Please try again.',
      );
    }
  }

  /// Clears the cached Google account so the chooser shows again next time.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      _log('Google sign-out failed: $error');
    }
  }

  bool _isCancel(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code == GoogleSignIn.kSignInCanceledError ||
        code.contains('popup_closed') ||
        code.contains('canceled') ||
        code.contains('cancelled') ||
        message.contains('popup_closed') ||
        // Android: ApiException 12501 = user cancelled.
        message.contains('12501');
  }

  String _messageFor(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == GoogleSignIn.kNetworkError || message.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (code.contains('popup_failed_to_open') || message.contains('popup_failed_to_open') ||
        message.contains('popup blocked')) {
      return 'Your browser blocked the Google sign-in popup. Please allow popups for this site and try again.';
    }
    // Android ApiException 10 (DEVELOPER_ERROR), invalid client / origin, etc.
    if (message.contains('apiexception: 10') ||
        message.contains('idpiframe_initialization_failed') ||
        message.contains('invalid_client') ||
        message.contains('origin')) {
      return 'Google Sign-In is not configured correctly for this app. Please try again later.';
    }
    return 'Google Sign-In is currently unavailable. Please try again.';
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[GoogleAuth] $message');
  }
}

