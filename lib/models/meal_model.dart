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
    cookId: (json['cook'] is Map
            ? json['cook']['_id']?.toString()
            : json['cook']?.toString()) ??
        (json['cookId'] is Map
            ? json['cookId']['_id']?.toString()
            : json['cookId']?.toString()),
    cookName: (json['cook'] is Map
            ? (json['cook']['kitchenName'] ?? json['cook']['name'])?.toString()
            : null) ??
        (json['cookId'] is Map
            ? (json['cookId']['kitchenName'] ?? json['cookId']['name'])?.toString()
            : json['cookName']?.toString()),
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
