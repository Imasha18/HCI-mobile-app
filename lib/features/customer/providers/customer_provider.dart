import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';

final customerProvider = NotifierProvider<CustomerNotifier, CustomerState>(
  CustomerNotifier.new,
);

class CustomerState {
  const CustomerState({this.isLoading = false, this.user, this.error});

  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? error;
}

class CustomerNotifier extends Notifier<CustomerState> {
  final _storage = const FlutterSecureStorage();

  @override
  CustomerState build() => const CustomerState();

  Future<bool> restoreSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) return false;
    try {
      final response = await ApiClient().dio.get('/auth/me');
      final user = response.data['data'] as Map<String, dynamic>;
      if (user['role'] != 'customer') return false;
      state = CustomerState(user: user);
      return true;
    } on DioException {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    state = const CustomerState();
  }

  Future<bool> login(String email, String password) async {
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
      await _storage.write(
        key: 'auth_token',
        value: payload['token'] as String,
      );
      state = CustomerState(user: user);
      return true;
    } on DioException catch (error) {
      state = CustomerState(error: ApiClient.messageFrom(error));
      return false;
    }
  }
}
