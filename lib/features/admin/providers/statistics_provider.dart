import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class StatisticsState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  const StatisticsState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  StatisticsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? data,
  }) {
    return StatisticsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  StatisticsNotifier(this._client) : super(const StatisticsState()) {
    fetchStatistics();
  }

  final ApiClient _client;

  Future<void> fetchStatistics() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _client.dio.get('/admin/statistics');
      state = state.copyWith(
        isLoading: false,
        data: res.data['data'] as Map<String, dynamic>,
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
        error: 'Failed to fetch statistics: $e',
      );
    }
  }
}

final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier(ApiClient());
});
