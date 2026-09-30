import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class OrderManagementState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> meals;

  const OrderManagementState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.meals = const [],
  });

  OrderManagementState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? orders,
    List<Map<String, dynamic>>? meals,
  }) {
    return OrderManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      orders: orders ?? this.orders,
      meals: meals ?? this.meals,
    );
  }
}

class OrderManagementNotifier extends StateNotifier<OrderManagementState> {
  OrderManagementNotifier(this._client) : super(const OrderManagementState()) {
    loadOrders();
    loadMeals();
  }

  final ApiClient _client;

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _client.dio.get('/admin/orders');
      final dataList = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        orders: dataList,
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
        error: 'Failed to load orders: $e',
      );
    }
  }

  Future<void> loadMeals() async {
    try {
      final res = await _client.dio.get('/admin/meals');
      final dataList = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      state = state.copyWith(
        meals: dataList,
      );
    } catch (_) {}
  }

  Future<bool> deleteMeal(String mealId) async {
    try {
      final res = await _client.dio.delete('/admin/meals/$mealId');
      if (res.data['success'] == true) {
        await loadMeals();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final orderManagementProvider = StateNotifierProvider<OrderManagementNotifier, OrderManagementState>((ref) {
  return OrderManagementNotifier(ApiClient());
});
