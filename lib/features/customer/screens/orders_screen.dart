import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: RefreshIndicator(
        color: const Color(0xFFFF9800),
        onRefresh: () async {
          ref.invalidate(orderProvider);
        },
        child: orders.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.builder(
                  key: const PageStorageKey<String>('my_orders_scroll'),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final order = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF3E0),
                          child: Icon(Icons.receipt_long, color: Color(0xFFFF9800)),
                        ),
                        title: Text(
                          'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: order.status == 'delivered'
                                ? Colors.green
                                : const Color(0xFFFF9800),
                          ),
                        ),
                        trailing: Text(
                          'Rs ${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.tracking,
                          arguments: order.id,
                        ),
                      ),
                    );
                  },
                ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error.toString().replaceFirst('Exception: ', '')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(orderProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => const OrderCardSkeleton(),
          ),
        ),
      ),
    );
  }
}
