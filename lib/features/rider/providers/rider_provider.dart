import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';

class RiderState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? rider;
  final Map<String, dynamic>? dashboardData;
  final bool isOnline;

  const RiderState({
    this.isLoading = false,
    this.error,
    this.rider,
    this.dashboardData,
    this.isOnline = true,
  });

  RiderState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? rider,
    Map<String, dynamic>? dashboardData,
    bool? isOnline,
  }) {
    return RiderState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      rider: rider ?? this.rider,
      dashboardData: dashboardData ?? this.dashboardData,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class RiderNotifier extends StateNotifier<RiderState> {
  RiderNotifier(this._client, this._storage) : super(const RiderState()) {
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

  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {
          'email': emailOrPhone.trim(),
          'password': password,
          'role': 'rider',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);

      state = state.copyWith(
        isLoading: false,
        rider: user,
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
        error: 'An unexpected error occurred during rider login.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? vehicleType,
    String? vehicleModel,
    String? vehiclePlateNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/register-rider',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'phone': phone?.trim() ?? '+94 77 123 4567',
          'address': address?.trim() ?? 'Colombo, Sri Lanka',
          'vehicleType': vehicleType?.trim() ?? 'Motorbike',
          'vehicleModel': vehicleModel?.trim() ?? 'Honda Dio',
          'vehiclePlateNumber': vehiclePlateNumber?.trim() ?? 'WP BZ-4892',
          'role': 'rider',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);

      state = state.copyWith(
        isLoading: false,
        rider: user,
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
        error: 'Failed to create rider account: $e',
      );
      return false;
    }
  }

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    try {
      final response = await _client.getCached(
        '/rider/dashboard',
        forceRefresh: forceRefresh,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final riderInfo = data['rider'] as Map<String, dynamic>?;
        state = state.copyWith(
          dashboardData: data,
          isOnline: riderInfo?['isOnline'] as bool? ?? state.isOnline,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(error: ApiClient.messageFrom(e));
    } catch (_) {}
  }

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    try {
      final response = await _client.getCached(
        '/rider/profile',
        forceRefresh: forceRefresh,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(
          rider: data,
          isOnline: data['isOnline'] as bool? ?? state.isOnline,
        );
      }
    } catch (_) {}
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final previous = state.isOnline;
    state = state.copyWith(isOnline: isOnline);
    try {
      await _client.dio.put('/rider/profile', data: {'isOnline': isOnline});
      await fetchDashboard();
    } catch (_) {
      state = state.copyWith(isOnline: previous);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/rider/profile', data: updateData);
      final updatedRider = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        rider: updatedRider,
        isOnline: updatedRider['isOnline'] as bool? ?? state.isOnline,
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

  Future<void> updateLocation(double lat, double lng) async {
    try {
      await _client.dio.patch('/rider/location', data: {
        'latitude': lat,
        'longitude': lng,
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    state = const RiderState();
  }
}

final riderProvider = StateNotifierProvider<RiderNotifier, RiderState>((ref) {
  return RiderNotifier(ApiClient(), const FlutterSecureStorage());
});
