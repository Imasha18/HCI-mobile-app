import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_provider.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: FutureBuilder(
        future: ref.read(orderProvider.notifier).getOrder(orderId),
        builder: (context, snapshot) {
          final status = snapshot.data?.status ?? 'pending';
          final steps = [
            'Order Placed',
            'Cook Accepted',
            'Preparing',
            'Ready for Pickup',
            'Rider Assigned',
            'Out for Delivery',
            'Delivered',
          ];
          final active = steps.indexWhere(
            (step) => step.toLowerCase().contains(status.toLowerCase()),
          );
          final completed = active < 0 ? 0 : active;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 72,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ...steps.asMap().entries.map((entry) {
                final isComplete = entry.key <= completed;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isComplete
                        ? const Color(0xFFFF7A00)
                        : Colors.grey.shade200,
                    child: Icon(
                      isComplete ? Icons.check : Icons.circle,
                      color: isComplete ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                  ),
                  title: Text(entry.value),
                  subtitle: entry.key == 0
                      ? const Text('We received your order')
                      : null,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
