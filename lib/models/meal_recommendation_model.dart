import 'meal_model.dart';

class MealRecommendation {
  final MealModel meal;
  final List<String> reasons;
  final double? score;

  const MealRecommendation({
    required this.meal,
    required this.reasons,
    this.score,
  });

  factory MealRecommendation.fromJson(Map<String, dynamic> json) {
    final rawMeal = json['meal'] as Map<String, dynamic>? ?? json;
    final reasonsList = (json['reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final scoreVal = (json['score'] as num?)?.toDouble();

    return MealRecommendation(
      meal: MealModel.fromJson(rawMeal),
      reasons: reasonsList,
      score: scoreVal,
    );
  }

  Map<String, dynamic> toJson() => {
        'meal': {
          'id': meal.id,
          'name': meal.name,
          'price': meal.price,
          'description': meal.description,
          'category': meal.category,
          'imageUrl': meal.imageUrl,
          'rating': meal.rating,
          'cookId': meal.cookId,
          'cookName': meal.cookName,
        },
        'reasons': reasons,
        if (score != null) 'score': score,
      };
}
