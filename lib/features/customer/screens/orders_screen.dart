import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No orders yet'))
            : ListView(
                children: items
                    .map(
                      (order) => ListTile(
                        title: Text(
                          'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                        ),
                        subtitle: Text(order.status),
                        trailing: Text('Rs ${order.total.toStringAsFixed(2)}'),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.tracking,
                          arguments: order.id,
                        ),
                      ),
                    )
                    .toList(),
              ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
