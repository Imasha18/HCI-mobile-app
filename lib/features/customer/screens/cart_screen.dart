import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: cart.when(
        data: (value) => value.items.isEmpty
            ? const Center(child: Text('Your cart is empty'))
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: value.items
                          .map(
                            (item) => ListTile(
                              title: Text(item.meal.name),
                              subtitle: Text(
                                '\$${item.meal.price.toStringAsFixed(2)}',
                              ),
                              leading: IconButton(
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(
                                      item.meal.id,
                                      item.quantity - 1,
                                    ),
                                icon: const Icon(Icons.remove),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${item.quantity}'),
                                  IconButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                          item.meal.id,
                                          item.quantity + 1,
                                        ),
                                    icon: const Icon(Icons.add),
                                  ),
                                  IconButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .remove(item.meal.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(
                          '\$${value.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        error: (error, _) => Center(child: Text('Unable to load cart: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
