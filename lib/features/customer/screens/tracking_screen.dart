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
          final status = (snapshot.data?.status ?? 'Order Received').trim();
          final sLower = status.toLowerCase();
          final steps = [
            'Order Received',
            'Cook Accepted',
            'Preparing',
            'Ready for Pickup',
            'Rider Assigned',
            'Out for Delivery',
            'Delivered',
          ];
          int completed = 0;
          if (sLower.contains('delivered') || sLower.contains('completed')) {
            completed = 6;
          } else if (sLower.contains('out') || sLower.contains('delivery')) {
            completed = 5;
          } else if (sLower.contains('rider')) {
            completed = 4;
          } else if (sLower.contains('ready') || sLower.contains('pickup')) {
            completed = 3;
          } else if (sLower.contains('preparing')) {
            completed = 2;
          } else if (sLower.contains('accepted')) {
            completed = 1;
          } else {
            completed = 0;
          }
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
              const SizedBox(height: 16),
              if (snapshot.data?.riderName != null) ...[
                Card(
                  elevation: 0,
                  color: const Color(0xFFE8FBEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF20C957), width: 1.2),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF20C957),
                      child: Icon(Icons.delivery_dining, color: Colors.white),
                    ),
                    title: Text(
                      snapshot.data!.riderName!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(snapshot.data?.riderPhone ?? 'HomeBite Delivery Rider'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20C957),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Call', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
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
