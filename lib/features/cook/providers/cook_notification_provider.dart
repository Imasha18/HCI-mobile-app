import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class CookNotificationState {
  final bool isLoading;
  final String? error;
  final List<dynamic> notifications;

  const CookNotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
  });

  CookNotificationState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<dynamic>? notifications,
  }) {
    return CookNotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      notifications: notifications ?? this.notifications,
    );
  }
}

class CookNotificationNotifier extends StateNotifier<CookNotificationState> {
  CookNotificationNotifier(this._client) : super(const CookNotificationState()) {
    fetchNotifications();
  }

  final ApiClient _client;

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/notifications');
      final data = response.data['data'] as List<dynamic>;
      state = state.copyWith(isLoading: false, notifications: data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch notifications',
      );
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client.dio.patch('/notifications/$id/read');
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.dio.patch('/notifications/read-all');
      await fetchNotifications();
    } catch (_) {}
  }
}

final cookNotificationProvider =
    StateNotifierProvider<CookNotificationNotifier, CookNotificationState>((ref) {
  return CookNotificationNotifier(ApiClient());
});
