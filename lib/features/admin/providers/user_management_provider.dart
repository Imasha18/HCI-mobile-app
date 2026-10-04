import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class UserManagementState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> cooks;
  final List<Map<String, dynamic>> riders;

  const UserManagementState({
    this.isLoading = false,
    this.error,
    this.users = const [],
    this.customers = const [],
    this.cooks = const [],
    this.riders = const [],
  });

  UserManagementState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? customers,
    List<Map<String, dynamic>>? cooks,
    List<Map<String, dynamic>>? riders,
  }) {
    return UserManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      users: users ?? this.users,
      customers: customers ?? this.customers,
      cooks: cooks ?? this.cooks,
      riders: riders ?? this.riders,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  UserManagementNotifier(this._client) : super(const UserManagementState()) {
    loadAllUsers();
  }

  final ApiClient _client;

  Future<void> loadAllUsers({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: state.users.isEmpty, clearError: true);
    try {
      final res = await _client.getCached('/admin/users', forceRefresh: forceRefresh);
      final dataList = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        users: dataList,
        clearError: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load users: $e',
      );
    }
  }

  Future<void> loadCustomers({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: state.customers.isEmpty, clearError: true);
    try {
      final res = await _client.getCached('/admin/customers', forceRefresh: forceRefresh);
      final dataList = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        customers: dataList,
        clearError: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load customers: $e',
      );
    }
  }

  Future<void> loadCooks({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: state.cooks.isEmpty, clearError: true);
    try {
      final res = await _client.getCached('/admin/cooks', forceRefresh: forceRefresh);
      final dataList = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        cooks: dataList,
        clearError: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load cooks: $e',
      );
    }
  }

  Future<void> loadRiders({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: state.riders.isEmpty, clearError: true);
    try {
      final res = await _client.getCached('/admin/riders', forceRefresh: forceRefresh);
      final dataList = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        riders: dataList,
        clearError: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load riders: $e',
      );
    }
  }

  void _invalidateUserCaches() {
    _client.invalidateCache('/admin/users');
    _client.invalidateCache('/admin/customers');
    _client.invalidateCache('/admin/cooks');
    _client.invalidateCache('/admin/riders');
  }

  Future<bool> blockUser(String id) async {
    try {
      final res = await _client.dio.patch('/admin/users/$id/block');
      if (res.data['success'] == true) {
        _invalidateUserCaches();
        await loadAllUsers(forceRefresh: true);
        await loadCustomers(forceRefresh: true);
        await loadCooks(forceRefresh: true);
        await loadRiders(forceRefresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockUser(String id) async {
    try {
      final res = await _client.dio.patch('/admin/users/$id/unblock');
      if (res.data['success'] == true) {
        _invalidateUserCaches();
        await loadAllUsers(forceRefresh: true);
        await loadCustomers(forceRefresh: true);
        await loadCooks(forceRefresh: true);
        await loadRiders(forceRefresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final res = await _client.dio.delete('/admin/users/$id');
      if (res.data['success'] == true) {
        _invalidateUserCaches();
        await loadAllUsers(forceRefresh: true);
        await loadCustomers(forceRefresh: true);
        await loadCooks(forceRefresh: true);
        await loadRiders(forceRefresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyCook(String cookId, String status) async {
    try {
      final res = await _client.dio.patch('/admin/cooks/$cookId/verify', data: {
        'status': status,
      });
      if (res.data['success'] == true) {
        _invalidateUserCaches();
        await loadCooks(forceRefresh: true);
        await loadAllUsers(forceRefresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyRider(String riderId, String status) async {
    try {
      final res = await _client.dio.patch('/admin/riders/$riderId/verify', data: {
        'status': status,
      });
      if (res.data['success'] == true) {
        _invalidateUserCaches();
        await loadRiders(forceRefresh: true);
        await loadAllUsers(forceRefresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier(ApiClient());
});
