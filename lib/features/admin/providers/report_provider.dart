import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class ReportState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  const ReportState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  ReportState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? data,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier(this._client) : super(const ReportState()) {
    fetchReports();
  }

  final ApiClient _client;

  Future<void> fetchReports() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _client.dio.get('/admin/reports');
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
        error: 'Failed to generate reports: $e',
      );
    }
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ApiClient());
});
