import 'meal_model.dart';

class CartModel {
  const CartModel({this.items = const []});
  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
    items: ((json['items'] as List?) ?? [])
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
  final List<CartItem> items;
  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.meal.price * item.quantity);
}

class CartItem {
  const CartItem({required this.meal, required this.quantity});
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    meal: MealModel.fromJson(json['meal'] as Map<String, dynamic>),
    quantity: json['quantity'] as int? ?? 1,
  );
  final MealModel meal;
  final int quantity;
}
