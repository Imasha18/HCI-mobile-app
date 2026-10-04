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
    try {
      final response = await ApiClient().getCached(
        '/cooks',
        ttl: const Duration(minutes: 2),
        forceRefresh: forceRefresh,
      );
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      final cooks = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      state = AsyncData(cooks);
      return cooks;
    } on DioException catch (error, stackTrace) {
      final exception = Exception(ApiClient.messageFrom(error));
      state = AsyncError(exception, stackTrace);
      return [];
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return [];
    }
  }
}
