import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_preferences_model.dart';
import '../../../models/meal_recommendation_model.dart';
import '../../../services/api_client.dart';

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(
  RecommendationNotifier.new,
);

class RecommendationState {
  final List<MealRecommendation> recommendations;
  final bool isLoading;
  final bool isSavingPreferences;
  final CustomerPreferences preferences;
  final bool isBannerDismissed;
  final String? error;

  const RecommendationState({
    this.recommendations = const [],
    this.isLoading = false,
    this.isSavingPreferences = false,
    this.preferences = const CustomerPreferences(),
    this.isBannerDismissed = false,
    this.error,
  });

  bool get shouldShowOnboardingBanner =>
      !isBannerDismissed && !preferences.hasSetPreferences;

  RecommendationState copyWith({
    List<MealRecommendation>? recommendations,
    bool? isLoading,
    bool? isSavingPreferences,
    CustomerPreferences? preferences,
    bool? isBannerDismissed,
    String? error,
    bool clearError = false,
  }) {
    return RecommendationState(
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      isSavingPreferences: isSavingPreferences ?? this.isSavingPreferences,
      preferences: preferences ?? this.preferences,
      isBannerDismissed: isBannerDismissed ?? this.isBannerDismissed,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RecommendationNotifier extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    Future.microtask(() {
      loadPreferences();
      loadRecommendations();
    });
    return const RecommendationState();
  }

  Future<void> loadPreferences() async {
    try {
      final response = await ApiClient().getCached(
        '/recommendations/preferences',
        ttl: const Duration(minutes: 5),
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && data['preferences'] is Map<String, dynamic>) {
        final prefs = CustomerPreferences.fromJson(
          data['preferences'] as Map<String, dynamic>,
        );
        state = state.copyWith(preferences: prefs);
      }
    } catch (_) {
      // Preferences load failure is non-fatal
    }
  }

  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiClient().getCached(
        '/recommendations/meals',
        ttl: const Duration(minutes: 2),
        forceRefresh: forceRefresh,
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      final rawList = data?['recommendations'] as List<dynamic>? ?? [];

      final items = rawList
          .map((item) =>
              MealRecommendation.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        recommendations: items,
        clearError: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        recommendations: const [],
        error: error.response?.statusCode == 401
            ? null
            : ApiClient.messageFrom(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        recommendations: const [],
      );
    }
  }

  Future<bool> savePreferences(CustomerPreferences newPrefs) async {
    state = state.copyWith(isSavingPreferences: true, clearError: true);

    try {
      final payload = newPrefs.toJson()..['onboardingCompleted'] = true;
      final response = await ApiClient().dio.put(
        '/recommendations/preferences',
        data: payload,
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      final updatedPrefs = data?['preferences'] is Map<String, dynamic>
          ? CustomerPreferences.fromJson(
              data!['preferences'] as Map<String, dynamic>,
            )
          : newPrefs.copyWith(onboardingCompleted: true);

      ApiClient().clearCache();

      state = state.copyWith(
        isSavingPreferences: false,
        preferences: updatedPrefs,
        isBannerDismissed: true,
        clearError: true,
      );

      await loadRecommendations(forceRefresh: true);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isSavingPreferences: false,
        error: ApiClient.messageFrom(error),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSavingPreferences: false,
        error: 'Failed to save food preferences.',
      );
      return false;
    }
  }

  void dismissOnboardingBanner() {
    state = state.copyWith(isBannerDismissed: true);
  }

  void trackInteraction(
    String mealId,
    String eventType, [
    Map<String, dynamic>? metadata,
  ]) {
    Future(() async {
      try {
        final payload = <String, dynamic>{
          'mealId': mealId,
          'eventType': eventType,
        };
        if (metadata != null) {
          payload['metadata'] = metadata;
        }
        await ApiClient().dio.post(
          '/recommendations/track',
          data: payload,
        );
      } catch (_) {
        // Ignored non-critical tracking errors
      }
    });
  }
}
