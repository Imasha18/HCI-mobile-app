import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/cart_model.dart';
import '../../../models/meal_model.dart';
import '../../../services/api_client.dart';

final cartProvider = AsyncNotifierProvider<CartNotifier, CartModel>(
  CartNotifier.new,
);

class CartNotifier extends AsyncNotifier<CartModel> {
  @override
  Future<CartModel> build() async {
    final response = await ApiClient().dio.get('/cart');
    final data = response.data['data'];
    return data == null
        ? const CartModel()
        : CartModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> add(MealModel meal) async {
    await ApiClient().dio.post('/cart/items', data: {'mealId': meal.id});
    ref.invalidateSelf();
  }

  Future<void> updateQuantity(String mealId, int quantity) async {
    await ApiClient().dio.put(
      '/cart/items/$mealId',
      data: {'quantity': quantity},
    );
    ref.invalidateSelf();
  }

  Future<void> remove(String mealId) async {
    await ApiClient().dio.delete('/cart/items/$mealId');
    ref.invalidateSelf();
  }
}
