import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';

final customerProvider = NotifierProvider<CustomerNotifier, CustomerState>(
  CustomerNotifier.new,
);

class CustomerState {
  const CustomerState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.user,
    this.error,
  });

  final bool isLoading;
  final bool isRefreshing;
  final Map<String, dynamic>? user;
  final String? error;

  CustomerState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    Map<String, dynamic>? user,
    String? error,
    bool clearError = false,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CustomerNotifier extends Notifier<CustomerState> {
  final _storage = const FlutterSecureStorage();

  @override
  CustomerState build() => const CustomerState();

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> data) {
    final rawUser = Map<String, dynamic>.from(data);
    final role = rawUser['role'];
    return {
      ...rawUser,
      'id': rawUser['_id'] ?? rawUser['id'] ?? '',
      'role': role ?? 'customer',
      'name': rawUser['name'] ?? 'HomeBite customer',
      'email': rawUser['email'] ?? '',
      'profileImage': rawUser['profileImage'] ?? rawUser['avatar'] ?? '',
    };
  }

  Future<bool> loadProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && state.user != null) {
      return true;
    }

    state = state.copyWith(
      isLoading: state.user == null,
      isRefreshing: forceRefresh && state.user != null,
      clearError: true,
    );

    try {
      final response = await ApiClient().getCached(
        '/auth/me',
        ttl: const Duration(minutes: 2),
        forceRefresh: forceRefresh,
      );
      final payload = response.data['data'] as Map<String, dynamic>? ??
          <String, dynamic>{};
      final user = _normalizeUser(payload);
      if (user['role'] != 'customer') {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Customer access only.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        user: user,
        clearError: true,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: ApiClient.messageFrom(error),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Unable to load your profile right now.',
      );
      return false;
    }
  }

  Future<bool> restoreSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) return false;
    ApiClient().updateAuthToken(token);
    try {
      final response = await ApiClient().getCached(
        '/auth/me',
        ttl: const Duration(minutes: 2),
      );
      final payload = response.data['data'] as Map<String, dynamic>? ??
          <String, dynamic>{};
      final user = _normalizeUser(payload);
      if (user['role'] != 'customer') return false;
      state = state.copyWith(
        user: user,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
      return true;
    } on DioException {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    ApiClient().clearCache();
    state = const CustomerState();
  }

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      state = const CustomerState(error: 'Email and password are required.');
      return false;
    }
    if (password.trim().length < 6) {
      state = const CustomerState(
        error: 'Password must be at least 6 characters.',
      );
      return false;
    }
    state = const CustomerState(isLoading: true);
    try {
      final response = await ApiClient().dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final payload = response.data['data'] as Map<String, dynamic>;
      final user = payload['user'] as Map<String, dynamic>;
      if (user['role'] != 'customer') {
        state = const CustomerState(error: 'This login is for customers only.');
        return false;
      }
      final token = payload['token'] as String;
      await _storage.write(
        key: 'auth_token',
        value: token,
      );
      ApiClient().updateAuthToken(token);
      state = CustomerState(user: user);
      return true;
    } on DioException catch (error) {
      await _storage.delete(key: 'auth_token');
      ApiClient().clearCache();
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    if (name.trim().length < 2 ||
        email.trim().isEmpty ||
        password.trim().length < 6) {
      state = const CustomerState(
        error:
            'Enter a name, valid email, and password of at least 6 characters.',
      );
      return false;
    }
    state = const CustomerState(isLoading: true);
    try {
      await ApiClient().dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      state = CustomerState(user: {'email': email.trim()});
      return true;
    } on DioException catch (error) {
      await _storage.delete(key: 'auth_token');
      ApiClient().clearCache();
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = const CustomerState(isLoading: true);
    try {
      final response = await ApiClient().dio.post(
        '/auth/verify-email',
        data: {'email': email.trim(), 'code': code.trim()},
      );
      final payload = response.data['data'] as Map<String, dynamic>;
      final token = payload['token'] as String;
      await _storage.write(
        key: 'auth_token',
        value: token,
      );
      ApiClient().updateAuthToken(token);
      state = CustomerState(user: payload['user'] as Map<String, dynamic>);
      return true;
    } on DioException catch (error) {
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }

  Future<bool> googleLogin(String idToken) async {
    try {
      final response = await ApiClient().dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );
      final payload = response.data['data'] as Map<String, dynamic>;
      final token = payload['token'] as String;
      await _storage.write(
        key: 'auth_token',
        value: token,
      );
      ApiClient().updateAuthToken(token);
      state = CustomerState(user: payload['user'] as Map<String, dynamic>);
      return true;
    } on DioException catch (error) {
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    if (!email.contains('@')) {
      state = const CustomerState(error: 'Enter a valid email address.');
      return false;
    }
    state = const CustomerState(isLoading: true);
    try {
      await ApiClient().dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      state = CustomerState(user: {'email': email.trim()});
      return true;
    } on DioException catch (error) {
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }

  Future<bool> resetPassword(String email, String code, String password) async {
    if (code.trim().length != 6 || password.trim().length < 6) {
      state = const CustomerState(
        error:
            'Enter the 6-digit code and a password of at least 6 characters.',
      );
      return false;
    }
    state = const CustomerState(isLoading: true);
    try {
      await ApiClient().dio.post(
        '/auth/reset-password',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'password': password,
        },
      );
      state = const CustomerState();
      return true;
    } on DioException catch (error) {
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }
}
