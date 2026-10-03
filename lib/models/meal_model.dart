class MealModel {
  const MealModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.category,
    this.imageUrl,
    this.rating,
    this.cookId,
    this.cookName,
  });
  factory MealModel.fromJson(Map<String, dynamic> json) => MealModel(
    id: json['_id'] as String? ?? json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Meal',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    description: json['description'] as String?,
    category: json['category'] as String?,
    imageUrl: (json['imageUrl'] as String?)?.isNotEmpty == true
        ? json['imageUrl'] as String
        : (json['image'] as String?),
    rating: (json['rating'] as num?)?.toDouble(),
    cookId: (json['cook'] is Map ? json['cook']['_id'] : json['cook']) as String? ??
        (json['cookId'] as String?),
    cookName: json['cook'] is Map
        ? (json['cook']['kitchenName'] as String? ?? json['cook']['name'] as String?)
        : (json['cookName'] as String?),
  );
  final String id;
  final String name;
  final double price;
  final String? description;
  final String? category;
  final String? imageUrl;
  final double? rating;
  final String? cookId;
  final String? cookName;
}
