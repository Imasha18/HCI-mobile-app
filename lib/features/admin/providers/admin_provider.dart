import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';

class AdminState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? adminUser;
  final Map<String, dynamic>? dashboardData;

  const AdminState({
    this.isLoading = false,
    this.error,
    this.adminUser,
    this.dashboardData,
  });

  AdminState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? adminUser,
    Map<String, dynamic>? dashboardData,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      adminUser: adminUser ?? this.adminUser,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier(this._client, this._storage) : super(const AdminState()) {
    checkSession();
  }

  final ApiClient _client;
  final FlutterSecureStorage _storage;

  Future<void> checkSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      await fetchDashboard();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'role': 'admin',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final token = data['token'] as String;

      if (user['role'] != 'admin') {
        state = state.copyWith(
          isLoading: false,
          error: 'Access denied. Administrator privileges required.',
        );
        return false;
      }

      await _storage.write(key: 'auth_token', value: token);

      state = state.copyWith(
        isLoading: false,
        adminUser: user,
        clearError: true,
      );

      await fetchDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to sign in as admin. Please check connection.',
      );
      return false;
    }
  }

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    try {
      final response = await _client.getCached(
        '/admin/dashboard',
        forceRefresh: forceRefresh,
      );
      if (response.data['success'] == true) {
        state = state.copyWith(
          dashboardData: response.data['data'] as Map<String, dynamic>,
          clearError: true,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(error: ApiClient.messageFrom(e));
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    state = const AdminState();
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ApiClient(), const FlutterSecureStorage());
});
