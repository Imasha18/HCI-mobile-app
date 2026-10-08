import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import 'api_client.dart';

class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({
    required this.token,
    required this.user,
  });
}

class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage;

  AuthService({
    ApiClient? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<AuthResponse> login(String email, String password) async {
    final response = await _client.dio.post(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final payload = response.data['data'] as Map<String, dynamic>;
    final token = payload['token'] as String;
    final userJson = payload['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await _storage.write(key: 'auth_token', value: token);
    _client.updateAuthToken(token);

    return AuthResponse(token: token, user: user);
  }

  Future<UserModel?> getProfile() async {
    final response = await _client.dio.get('/auth/me');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final userJson = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _client.clearCache();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
