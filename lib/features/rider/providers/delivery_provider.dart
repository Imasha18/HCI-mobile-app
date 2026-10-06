import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class DeliveryState {
  final bool isLoading;
  final String? error;
  final List<dynamic> availableDeliveries;
  final Map<String, dynamic>? selectedDelivery;
  final Map<String, dynamic>? activeDelivery;

  const DeliveryState({
    this.isLoading = false,
    this.error,
    this.availableDeliveries = const [],
    this.selectedDelivery,
    this.activeDelivery,
  });

  DeliveryState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<dynamic>? availableDeliveries,
    Map<String, dynamic>? selectedDelivery,
    Map<String, dynamic>? activeDelivery,
  }) {
    return DeliveryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      availableDeliveries: availableDeliveries ?? this.availableDeliveries,
      selectedDelivery: selectedDelivery ?? this.selectedDelivery,
      activeDelivery: activeDelivery ?? this.activeDelivery,
    );
  }
}

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  DeliveryNotifier(this._client) : super(const DeliveryState()) {
    fetchAvailableDeliveries();
  }

  final ApiClient _client;

  Future<void> fetchAvailableDeliveries() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/deliveries/available');
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      state = state.copyWith(
        isLoading: false,
        availableDeliveries: data,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load available deliveries',
      );
    }
  }

  Future<Map<String, dynamic>?> fetchDeliveryDetails(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/deliveries/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        selectedDelivery: data,
      );
      return data;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load delivery details',
      );
      return null;
    }
  }

  Future<bool> acceptDelivery(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.patch('/deliveries/$id/accept');
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        activeDelivery: data,
        selectedDelivery: data,
      );
      await fetchAvailableDeliveries();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to accept delivery',
      );
      return false;
    }
  }

  Future<bool> pickupDelivery(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.patch('/deliveries/$id/pickup');
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        activeDelivery: data,
        selectedDelivery: data,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update pickup status',
      );
      return false;
    }
  }

  Future<bool> startDelivery(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.patch('/deliveries/$id/start');
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        activeDelivery: data,
        selectedDelivery: data,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update delivery transit status',
      );
      return false;
    }
  }

  Future<bool> completeDelivery(String id, {String? proofImageUrl}) async {
    final payload = <String, dynamic>{};
    if (proofImageUrl != null) {
      payload['proofImageUrl'] = proofImageUrl;
    }
    try {
      final response = await _client.dio.patch(
        '/deliveries/$id/complete',
        data: payload,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        activeDelivery: null,
        selectedDelivery: data,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete delivery',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> createDelivery(Map<String, dynamic> deliveryData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post('/deliveries', data: deliveryData);
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false);
      await fetchAvailableDeliveries();
      return data;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to create delivery');
      return null;
    }
  }

  Future<bool> updateDelivery(String id, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/deliveries/$id', data: updateData);
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        selectedDelivery: data,
        activeDelivery: state.activeDelivery?['_id'] == id ? data : state.activeDelivery,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to update delivery');
      return false;
    }
  }

  Future<bool> cancelDelivery(String id, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final payload = <String, dynamic>{};
      if (reason != null) {
        payload['reason'] = reason;
      }
      final response = await _client.dio.patch('/deliveries/$id/cancel', data: payload);
      final data = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        selectedDelivery: data,
        activeDelivery: state.activeDelivery?['_id'] == id ? null : state.activeDelivery,
      );
      await fetchAvailableDeliveries();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to cancel delivery');
      return false;
    }
  }

  Future<bool> deleteDelivery(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _client.dio.delete('/deliveries/$id');
      state = state.copyWith(
        isLoading: false,
        activeDelivery: state.activeDelivery?['_id'] == id ? null : state.activeDelivery,
      );
      await fetchAvailableDeliveries();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to delete delivery');
      return false;
    }
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  return DeliveryNotifier(ApiClient());
});
