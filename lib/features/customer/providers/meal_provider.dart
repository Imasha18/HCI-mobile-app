import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/meal_model.dart';
import '../../../services/api_client.dart';

final mealProvider = AsyncNotifierProvider<MealNotifier, List<MealModel>>(
  MealNotifier.new,
);

final singleMealFamilyProvider = FutureProvider.family<MealModel, String>((ref, id) async {
  final response = await ApiClient().getCached(
    '/meals/$id',
    ttl: const Duration(minutes: 5),
  );
  return MealModel.fromJson(response.data['data'] as Map<String, dynamic>);
});

class MealNotifier extends AsyncNotifier<List<MealModel>> {
  @override
  Future<List<MealModel>> build() => fetchMeals();

  Future<List<MealModel>> fetchMeals({
    String? query,
    String? category,
    bool forceRefresh = false,
  }) async {
    // Preserve existing data while loading to prevent screen jumping
    final currentMeals = state.valueOrNull ?? [];

    try {
      final response = await ApiClient().getCached(
        '/meals/search',
        queryParameters: {
          ...query?.isNotEmpty == true ? {'q': query} : const <String, String?>{},
          ...category == null || category == 'All' ? const <String, String?>{} : {'category': category},
        },
        ttl: const Duration(seconds: 45),
        forceRefresh: forceRefresh,
      );
      final meals = (response.data['data'] as List<dynamic>)
          .map((item) => MealModel.fromJson(item as Map<String, dynamic>))
          .toList();
      state = AsyncData(meals);
      return meals;
    } on DioException catch (error, stackTrace) {
      if (currentMeals.isNotEmpty) {
        // Keep existing meals visible if background refresh fails
        return currentMeals;
      }
      final exception = Exception(ApiClient.messageFrom(error));
      state = AsyncError(exception, stackTrace);
      return [];
    } catch (e, stackTrace) {
      if (currentMeals.isNotEmpty) return currentMeals;
      state = AsyncError(e, stackTrace);
      return [];
    }
  }

  Future<MealModel> fetchMeal(String id) async {
    final response = await ApiClient().getCached('/meals/$id', ttl: const Duration(minutes: 5));
    return MealModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
