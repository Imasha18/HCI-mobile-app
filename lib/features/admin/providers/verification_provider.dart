import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class VerificationState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> pendingCooks;
  final List<Map<String, dynamic>> pendingRiders;

  const VerificationState({
    this.isLoading = false,
    this.error,
    this.pendingCooks = const [],
    this.pendingRiders = const [],
  });

  VerificationState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? pendingCooks,
    List<Map<String, dynamic>>? pendingRiders,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingCooks: pendingCooks ?? this.pendingCooks,
      pendingRiders: pendingRiders ?? this.pendingRiders,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier(this._client) : super(const VerificationState()) {
    loadPending();
  }

  final ApiClient _client;

  Future<void> loadPending() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cooksRes = await _client.dio.get('/admin/cooks');
      final ridersRes = await _client.dio.get('/admin/riders');

      final allCooks = (cooksRes.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final allRiders = (ridersRes.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final pendingCooks = allCooks.where((c) {
        final status = c['verificationStatus'] as String? ?? '';
        final isVerified = c['isVerified'] as bool? ?? false;
        return status == 'pending' || !isVerified;
      }).toList();

      final pendingRiders = allRiders.where((r) {
        final status = r['verificationStatus'] as String? ?? '';
        final isVerified = r['isVerified'] as bool? ?? false;
        return status == 'pending' || !isVerified;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        pendingCooks: pendingCooks,
        pendingRiders: pendingRiders,
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
        error: 'Failed to load verifications: $e',
      );
    }
  }

  Future<bool> verifyCook(String id, String status) async {
    try {
      final res = await _client.dio.patch('/admin/cooks/$id/verify', data: {'status': status});
      if (res.data['success'] == true) {
        await loadPending();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyRider(String id, String status) async {
    try {
      final res = await _client.dio.patch('/admin/riders/$id/verify', data: {'status': status});
      if (res.data['success'] == true) {
        await loadPending();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier(ApiClient());
});
