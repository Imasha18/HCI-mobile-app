import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class EarningsState {
  final bool isLoading;
  final String? error;
  final double totalEarnings;
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final List<dynamic> dailySales;
  final List<dynamic> recentEarnings;

  const EarningsState({
    this.isLoading = false,
    this.error,
    this.totalEarnings = 0.0,
    this.todayEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.dailySales = const [],
    this.recentEarnings = const [],
  });

  EarningsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    double? totalEarnings,
    double? todayEarnings,
    double? weeklyEarnings,
    double? monthlyEarnings,
    List<dynamic>? dailySales,
    List<dynamic>? recentEarnings,
  }) {
    return EarningsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      totalEarnings: totalEarnings ?? this.totalEarnings,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      dailySales: dailySales ?? this.dailySales,
      recentEarnings: recentEarnings ?? this.recentEarnings,
    );
  }
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  EarningsNotifier(this._client) : super(const EarningsState()) {
    fetchEarnings();
  }

  final ApiClient _client;

  Future<void> fetchEarnings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/cook/earnings');
      final data = response.data['data'] as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        todayEarnings: (data['todayEarnings'] as num?)?.toDouble() ?? 0.0,
        weeklyEarnings: (data['weeklyEarnings'] as num?)?.toDouble() ?? 0.0,
        monthlyEarnings: (data['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
        dailySales: (data['dailySales'] as List<dynamic>?) ?? [],
        recentEarnings: (data['recentEarnings'] as List<dynamic>?) ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load earnings data',
      );
    }
  }
}

final earningsProvider = StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  return EarningsNotifier(ApiClient());
});
