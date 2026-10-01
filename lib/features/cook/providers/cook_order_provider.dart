import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class CookOrderState {
  final bool isLoading;
  final String? error;
  final List<dynamic> orders;
  final Map<String, dynamic>? selectedOrder;
  final String selectedFilter;

  const CookOrderState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.selectedOrder,
    this.selectedFilter = 'All',
  });

  CookOrderState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<dynamic>? orders,
    Map<String, dynamic>? selectedOrder,
    String? selectedFilter,
  }) {
    return CookOrderState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class CookOrderNotifier extends StateNotifier<CookOrderState> {
  CookOrderNotifier(this._client) : super(const CookOrderState()) {
    fetchOrders();
  }

  final ApiClient _client;

  Future<void> fetchOrders([String? status]) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final endpoint = (status != null && status != 'All')
          ? '/cook/orders?status=${Uri.encodeComponent(status)}'
          : '/cook/orders';
      final response = await _client.dio.get(endpoint);
      final data = response.data['data'] as List<dynamic>;
      state = state.copyWith(isLoading: false, orders: data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to fetch orders');
    }
  }

  void filterOrders(String filter) {
    state = state.copyWith(selectedFilter: filter);
    fetchOrders(filter == 'All' ? null : filter);
  }

  Future<Map<String, dynamic>?> fetchOrderDetails(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/cook/orders/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, selectedOrder: data);
      return data;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load order');
      return null;
    }
  }

  Future<bool> acceptOrder(String id) async {
    try {
      await _client.dio.patch('/orders/$id/accept');
      await fetchOrders();
      await fetchOrderDetails(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectOrder(String id) async {
    try {
      await _client.dio.patch('/orders/$id/reject');
      await fetchOrders();
      await fetchOrderDetails(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    try {
      await _client.dio.patch(
        '/orders/$id/status',
        data: {'status': newStatus},
      );
      await fetchOrders();
      await fetchOrderDetails(id);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final cookOrderProvider =
    StateNotifierProvider<CookOrderNotifier, CookOrderState>((ref) {
  return CookOrderNotifier(ApiClient());
});
