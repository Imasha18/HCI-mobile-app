import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';
import 'delivery_provider.dart';
import 'earnings_provider.dart';
import 'notification_provider.dart';

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
  RiderNotifier(this._client, this._storage, this._ref) : super(const RiderState()) {
    checkAuthSession();
  }

  final ApiClient _client;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  void _resetOtherProviders() {
    try {
      _ref.read(deliveryProvider.notifier).reset();
      _ref.read(earningsProvider.notifier).reset();
      _ref.read(riderNotificationProvider.notifier).reset();
    } catch (_) {}
  }

  Future<void> checkAuthSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      _client.updateAuthToken(token);
      await fetchDashboard();
      await fetchProfile();
    }
  }

  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {
          'email': emailOrPhone.trim().toLowerCase(),
          'password': password,
          'role': 'rider',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      // Clear any prior cached data from previous sessions
      _client.clearCache();
      _client.updateAuthToken(token);

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: (user['id'] ?? user['_id'] ?? '').toString());

      _resetOtherProviders();

      state = state.copyWith(
        isLoading: false,
        rider: user,
        dashboardData: null,
        isOnline: user['isOnline'] as bool? ?? true,
      );

      await fetchDashboard(forceRefresh: true);
      await fetchProfile(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      final msg = ApiClient.messageFrom(e);
      state = state.copyWith(
        isLoading: false,
        error: msg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during rider login: $e',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
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
          'email': email.trim().toLowerCase(),
          'password': password,
          'phone': phone?.trim() ?? '',
          'address': address?.trim() ?? '',
          'vehicleType': vehicleType?.trim() ?? 'Motorbike',
          'vehicleModel': vehicleModel?.trim() ?? '',
          'vehiclePlateNumber': vehiclePlateNumber?.trim() ?? '',
          'role': 'rider',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final emailRequired = data['emailVerificationRequired'] == true;
      final user = data['user'] as Map<String, dynamic>?;

      state = state.copyWith(
        isLoading: false,
        rider: user,
      );

      return {
        'success': true,
        'emailVerificationRequired': emailRequired,
        'email': email.trim().toLowerCase(),
        'user': user,
      };
    } on DioException catch (e) {
      final errorMsg = ApiClient.messageFrom(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return {'success': false, 'error': errorMsg};
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create rider account: $e',
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/verify-email',
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      _client.clearCache();
      _client.updateAuthToken(token);

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: (user['id'] ?? user['_id'] ?? '').toString());

      _resetOtherProviders();

      state = state.copyWith(
        isLoading: false,
        rider: user,
        dashboardData: null,
        isOnline: user['isOnline'] as bool? ?? true,
      );

      await fetchDashboard(forceRefresh: true);
      await fetchProfile(forceRefresh: true);
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
        error: 'Email verification failed: $e',
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
          rider: riderInfo ?? state.rider,
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
      await fetchDashboard(forceRefresh: true);
    } catch (_) {
      state = state.copyWith(isOnline: previous);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/rider/profile', data: updateData);
      final updatedRider = response.data['data'] as Map<String, dynamic>;
      _client.clearCache('/rider');
      state = state.copyWith(
        isLoading: false,
        rider: updatedRider,
        isOnline: updatedRider['isOnline'] as bool? ?? state.isOnline,
      );
      await fetchDashboard(forceRefresh: true);
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
    await _storage.delete(key: 'user_id');
    _client.clearCache();
    _client.updateAuthToken(null);
    state = const RiderState();
    _resetOtherProviders();
  }
}

final riderProvider = StateNotifierProvider<RiderNotifier, RiderState>((ref) {
  return RiderNotifier(ApiClient(), const FlutterSecureStorage(), ref);
});
