import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';

class CookState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? cook;
  final Map<String, dynamic>? dashboardData;
  final bool isOnline;

  const CookState({
    this.isLoading = false,
    this.error,
    this.cook,
    this.dashboardData,
    this.isOnline = true,
  });

  CookState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? cook,
    Map<String, dynamic>? dashboardData,
    bool? isOnline,
  }) {
    return CookState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      cook: cook ?? this.cook,
      dashboardData: dashboardData ?? this.dashboardData,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class CookNotifier extends StateNotifier<CookState> {
  CookNotifier(this._client, this._storage) : super(const CookState()) {
    checkAuthSession();
  }

  final ApiClient _client;
  final FlutterSecureStorage _storage;

  Future<void> checkAuthSession() async {
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
          'role': 'cook',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);

      state = state.copyWith(
        isLoading: false,
        cook: user,
        isOnline: user['isOnline'] as bool? ?? true,
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
        error: 'An unexpected error occurred during login.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? kitchenName,
    String? phone,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/register-cook',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'kitchenName': kitchenName?.trim().isNotEmpty == true
              ? kitchenName!.trim()
              : '$name\'s Kitchen',
          'phone': phone?.trim() ?? '',
          'address': address?.trim() ?? '',
          'role': 'cook',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);

      state = state.copyWith(
        isLoading: false,
        cook: user,
        isOnline: user['isOnline'] as bool? ?? true,
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
        error: 'Failed to create cook account: $e',
      );
      return false;
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await _client.dio.get('/cooks/dashboard');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final cookInfo = data['cook'] as Map<String, dynamic>?;
        state = state.copyWith(
          dashboardData: data,
          isOnline: cookInfo?['isOnline'] as bool? ?? state.isOnline,
        );
      }
    } on DioException catch (e) {
      // Non-fatal on background fetch
      state = state.copyWith(error: ApiClient.messageFrom(e));
    } catch (_) {}
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final previous = state.isOnline;
    state = state.copyWith(isOnline: isOnline);
    try {
      await _client.dio.put('/cooks/profile', data: {'isOnline': isOnline});
      await fetchDashboard();
    } catch (_) {
      // Revert if error
      state = state.copyWith(isOnline: previous);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/cooks/profile', data: updateData);
      final updatedCook = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        cook: updatedCook,
        isOnline: updatedCook['isOnline'] as bool? ?? state.isOnline,
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
        error: 'Failed to update profile.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    state = const CookState();
  }
}

final cookProvider = StateNotifierProvider<CookNotifier, CookState>((ref) {
  return CookNotifier(ApiClient(), const FlutterSecureStorage());
});
