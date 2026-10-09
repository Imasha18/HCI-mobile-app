import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';

class RiderEarningsState {
  final double totalEarnings;
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final List<Map<String, dynamic>> dailyBreakdown;
  final List<Map<String, dynamic>> history;
  final bool isLoading;
  final String? error;

  const RiderEarningsState({
    this.totalEarnings = 0.0,
    this.todayEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.dailyBreakdown = const [],
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  RiderEarningsState copyWith({
    double? totalEarnings,
    double? todayEarnings,
    double? weeklyEarnings,
    double? monthlyEarnings,
    List<Map<String, dynamic>>? dailyBreakdown,
    List<Map<String, dynamic>>? history,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderEarningsState(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      dailyBreakdown: dailyBreakdown ?? this.dailyBreakdown,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EarningsNotifier extends StateNotifier<RiderEarningsState> {
  final ApiClient _client;

  EarningsNotifier(this._client) : super(const RiderEarningsState()) {
    fetchEarnings();
    fetchHistory();
  }

  Future<void> fetchEarnings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/rider/earnings');
      final data = response.data['data'] as Map<String, dynamic>;

      final rawBreakdown = (data['dailyBreakdown'] as List<dynamic>?) ?? [];
      final List<Map<String, dynamic>> breakdown = rawBreakdown.map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'day': map['day'] ?? 'Day',
          'amount': (map['amount'] as num?)?.toDouble() ?? 0.0,
          'deliveries': map['deliveries'] ?? 0,
        };
      }).toList();

      state = state.copyWith(
        isLoading: false,
        totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        todayEarnings: (data['todayEarnings'] as num?)?.toDouble() ?? 0.0,
        weeklyEarnings: (data['weeklyEarnings'] as num?)?.toDouble() ?? 0.0,
        monthlyEarnings: (data['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
        dailyBreakdown: breakdown,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchHistory() async {
    try {
      final response = await _client.dio.get('/rider/deliveries');
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      final typed = list.cast<Map<String, dynamic>>();
      state = state.copyWith(history: typed);
    } catch (_) {
      // Keep existing history
    }
  }

  void reset() {
    state = const RiderEarningsState();
  }
}

final earningsProvider = StateNotifierProvider<EarningsNotifier, RiderEarningsState>((ref) {
  return EarningsNotifier(ApiClient());
});
