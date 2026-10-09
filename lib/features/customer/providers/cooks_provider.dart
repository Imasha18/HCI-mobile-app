import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

final cooksProvider = AsyncNotifierProvider<CooksNotifier, List<Map<String, dynamic>>>(
  CooksNotifier.new,
);

class CooksNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() => fetchCooks();

  Future<List<Map<String, dynamic>>> fetchCooks({bool forceRefresh = false}) async {
    final currentCooks = state.valueOrNull ?? [];
    try {
      final response = await ApiClient().getCached(
        '/cooks',
        ttl: const Duration(minutes: 2),
        forceRefresh: forceRefresh,
      );

      final resData = response.data;
      final dynamic rawList = resData is Map
          ? (resData['data'] ?? resData['cooks'] ?? resData['kitchens'])
          : (resData is List ? resData : null);

      final List<dynamic> list = rawList is List ? rawList : const [];
      final cooks = list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      state = AsyncData(cooks);
      return cooks;
    } on DioException catch (error, stackTrace) {
      if (currentCooks.isNotEmpty) return currentCooks;
      final exception = Exception(ApiClient.messageFrom(error));
      state = AsyncError(exception, stackTrace);
      return [];
    } catch (e, stackTrace) {
      if (currentCooks.isNotEmpty) return currentCooks;
      state = AsyncError(e, stackTrace);
      return [];
    }
  }
}
