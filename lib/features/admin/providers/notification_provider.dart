import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class AdminNotificationState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> complaints;

  const AdminNotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
    this.complaints = const [],
  });

  AdminNotificationState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? complaints,
  }) {
    return AdminNotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      notifications: notifications ?? this.notifications,
      complaints: complaints ?? this.complaints,
    );
  }
}

class AdminNotificationNotifier extends StateNotifier<AdminNotificationState> {
  AdminNotificationNotifier(this._client) : super(const AdminNotificationState()) {
    fetchNotifications();
    fetchComplaints();
  }

  final ApiClient _client;

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _client.dio.get('/admin/notifications');
      final list = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        notifications: list,
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
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> fetchComplaints() async {
    try {
      final res = await _client.dio.get('/admin/complaints');
      final list = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(complaints: list);
    } catch (_) {}
  }

  Future<bool> resolveComplaint(String id, String response) async {
    try {
      final res = await _client.dio.patch('/admin/complaints/$id', data: {
        'status': 'resolved',
        'adminResponse': response,
      });
      if (res.data['success'] == true) {
        await fetchComplaints();
        await fetchNotifications();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectComplaint(String id) async {
    try {
      final res = await _client.dio.patch('/admin/complaints/$id', data: {
        'status': 'rejected',
      });
      if (res.data['success'] == true) {
        await fetchComplaints();
        await fetchNotifications();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final notificationProvider = StateNotifierProvider<AdminNotificationNotifier, AdminNotificationState>((ref) {
  return AdminNotificationNotifier(ApiClient());
});
