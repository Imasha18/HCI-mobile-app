import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class MealManagementState {
  final bool isLoading;
  final String? error;
  final List<dynamic> meals;
  final String selectedCategory;

  const MealManagementState({
    this.isLoading = false,
    this.error,
    this.meals = const [],
    this.selectedCategory = 'All',
  });

  MealManagementState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<dynamic>? meals,
    String? selectedCategory,
  }) {
    return MealManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      meals: meals ?? this.meals,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class MealManagementNotifier extends StateNotifier<MealManagementState> {
  MealManagementNotifier(this._client) : super(const MealManagementState()) {
    fetchMeals();
  }

  final ApiClient _client;

  Future<void> fetchMeals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.get('/cooks/meals');
      final data = response.data['data'] as List<dynamic>;
      state = state.copyWith(isLoading: false, meals: data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load meals',
      );
    }
  }

  void filterCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<bool> addMeal({
    required String name,
    required String description,
    required double price,
    required String category,
    required int cookingTime,
    required List<String> ingredients,
    required List<String> dietaryInfo,
    required bool available,
    String cuisine = 'Sri Lankan',
    String spiceLevel = 'medium',
    File? imageFile,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      dynamic dataPayload;
      if (imageFile != null) {
        dataPayload = FormData.fromMap({
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'cuisine': cuisine,
          'spiceLevel': spiceLevel,
          'cookingTime': cookingTime,
          'prepTimeMinutes': cookingTime,
          'ingredients': ingredients.join(', '),
          'dietaryInformation': dietaryInfo.join(', '),
          'dietaryTags': dietaryInfo.join(', '),
          'available': available,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });
      } else {
        dataPayload = {
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'cuisine': cuisine,
          'spiceLevel': spiceLevel,
          'cookingTime': cookingTime,
          'prepTimeMinutes': cookingTime,
          'ingredients': ingredients,
          'dietaryInformation': dietaryInfo,
          'dietaryTags': dietaryInfo,
          'available': available,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        };
      }

      await _client.dio.post('/meals', data: dataPayload);
      await fetchMeals();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create meal',
      );
      return false;
    }
  }

  Future<bool> editMeal({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required int cookingTime,
    required List<String> ingredients,
    required List<String> dietaryInfo,
    required bool available,
    String cuisine = 'Sri Lankan',
    String spiceLevel = 'medium',
    File? imageFile,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      dynamic dataPayload;
      if (imageFile != null) {
        dataPayload = FormData.fromMap({
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'cuisine': cuisine,
          'spiceLevel': spiceLevel,
          'cookingTime': cookingTime,
          'prepTimeMinutes': cookingTime,
          'ingredients': ingredients.join(', '),
          'dietaryInformation': dietaryInfo.join(', '),
          'dietaryTags': dietaryInfo.join(', '),
          'available': available,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });
      } else {
        dataPayload = {
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'cuisine': cuisine,
          'spiceLevel': spiceLevel,
          'cookingTime': cookingTime,
          'prepTimeMinutes': cookingTime,
          'ingredients': ingredients,
          'dietaryInformation': dietaryInfo,
          'dietaryTags': dietaryInfo,
          'available': available,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        };
      }

      await _client.dio.put('/meals/$id', data: dataPayload);
      await fetchMeals();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update meal',
      );
      return false;
    }
  }

  Future<bool> deleteMeal(String id) async {
    try {
      await _client.dio.delete('/meals/$id');
      await fetchMeals();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleAvailability(String id, bool newStatus) async {
    // Optimistic UI update
    final currentMeals = [...state.meals];
    final index = currentMeals.indexWhere((m) => m['_id'] == id);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(currentMeals[index]);
      updated['available'] = newStatus;
      currentMeals[index] = updated;
      state = state.copyWith(meals: currentMeals);
    }

    try {
      await _client.dio.patch('/meals/$id/availability', data: {'available': newStatus});
    } catch (_) {
      // Revert on failure
      fetchMeals();
    }
  }
}

final mealManagementProvider =
    StateNotifierProvider<MealManagementNotifier, MealManagementState>((ref) {
  return MealManagementNotifier(ApiClient());
});
