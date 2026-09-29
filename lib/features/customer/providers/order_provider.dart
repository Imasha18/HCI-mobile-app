import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/cart_model.dart';
import '../../../models/order_model.dart';
import '../../../services/api_client.dart';

final orderProvider = AsyncNotifierProvider<OrderNotifier, List<OrderModel>>(
  OrderNotifier.new,
);

class OrderNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    final response = await ApiClient().dio.get('/orders');
    return (response.data['data'] as List<dynamic>)
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> createOrder(CartModel cart, String address) async {
    final response = await ApiClient().dio.post(
      '/orders',
      data: {
        'deliveryAddress': address,
        'items': cart.items
            .map(
              (item) => {
                'meal': item.meal.id,
                'quantity': item.quantity,
                'price': item.meal.price,
              },
            )
            .toList(),
      },
    );
    ref.invalidateSelf();
    return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> getOrder(String id) async {
    final response = await ApiClient().dio.get('/orders/$id');
    return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
