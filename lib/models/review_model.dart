class ReviewModel {
  const ReviewModel({required this.rating, required this.comment, this.mealId});
  final double rating;
  final String comment;
  final String? mealId;
}
