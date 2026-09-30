import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';

class RiderNotificationState {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final String? error;

  const RiderNotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => n['read'] != true).length;

  RiderNotificationState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderNotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderNotificationNotifier extends StateNotifier<RiderNotificationState> {
  final ApiClient _client;

  RiderNotificationNotifier(this._client) : super(const RiderNotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/notifications');
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      final typed = list.cast<Map<String, dynamic>>();
      state = state.copyWith(isLoading: false, notifications: typed);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client.dio.patch('/notifications/$id/read');
      final updated = state.notifications.map((n) {
        if ((n['_id'] ?? n['id']) == id) {
          return {...n, 'read': true};
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.dio.patch('/notifications/read-all');
      final updated = state.notifications.map((n) => {...n, 'read': true}).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _client.dio.delete('/notifications/$id');
      final updated = state.notifications.where((n) => (n['_id'] ?? n['id']) != id).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }
}

final riderNotificationProvider =
    StateNotifierProvider<RiderNotificationNotifier, RiderNotificationState>((ref) {
  return RiderNotificationNotifier(ApiClient());
});
