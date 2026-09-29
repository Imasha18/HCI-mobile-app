import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../models/meal_model.dart';
import '../../../services/api_client.dart';

final mealProvider = AsyncNotifierProvider<MealNotifier, List<MealModel>>(
  MealNotifier.new,
);

class MealNotifier extends AsyncNotifier<List<MealModel>> {
  @override
  Future<List<MealModel>> build() => fetchMeals();

  Future<List<MealModel>> fetchMeals({String? query, String? category}) async {
    try {
      final response = await ApiClient().dio.get(
        '/meals/search',
        queryParameters: {
          ...query?.isNotEmpty == true
              ? {'q': query}
              : const <String, String?>{},
          ...category == null
              ? const <String, String?>{}
              : {'category': category},
        },
      );
      final meals = (response.data['data'] as List<dynamic>)
          .map((item) => MealModel.fromJson(item as Map<String, dynamic>))
          .toList();
      state = AsyncData(meals);
      return meals;
    } on DioException catch (error, stackTrace) {
      final exception = Exception(ApiClient.messageFrom(error));
      state = AsyncError(exception, stackTrace);
      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  Future<MealModel> fetchMeal(String id) async {
    final response = await ApiClient().dio.get('/meals/$id');
    return MealModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
