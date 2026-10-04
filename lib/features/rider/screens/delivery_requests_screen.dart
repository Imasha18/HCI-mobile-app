import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/delivery_provider.dart';
import '../theme/rider_theme.dart';

class DeliveryRequestsScreen extends ConsumerStatefulWidget {
  const DeliveryRequestsScreen({super.key});

  @override
  ConsumerState<DeliveryRequestsScreen> createState() => _DeliveryRequestsScreenState();
}

class _DeliveryRequestsScreenState extends ConsumerState<DeliveryRequestsScreen> {
  final Set<String> _dismissedIds = {};
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProvider.notifier).fetchAvailableDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryProvider);
    final available = state.availableDeliveries
        .where((d) => !_dismissedIds.contains((d['_id'] ?? d['id'] ?? '').toString()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'Delivery Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () => ref.read(deliveryProvider.notifier).fetchAvailableDeliveries(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.isLoading && available.isEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => const OrderCardSkeleton(),
            )
          : RefreshIndicator(
              color: RiderTheme.primaryGreen,
              onRefresh: () => ref.read(deliveryProvider.notifier).fetchAvailableDeliveries(),
              child: available.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: RiderTheme.secondaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: RiderTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Delivery Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: RiderTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'New incoming meal delivery requests from local home kitchens will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: RiderTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                onPressed: () => ref.read(deliveryProvider.notifier).fetchAvailableDeliveries(),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Check for Updates'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: RiderTheme.primaryDark,
                                  side: const BorderSide(color: RiderTheme.primaryGreen),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      key: const PageStorageKey<String>('rider_delivery_requests_scroll'),
                      padding: const EdgeInsets.all(16),
                      itemCount: available.length,
                      itemBuilder: (context, index) {
                        final delivery = available[index] as Map<String, dynamic>;
                        return _DeliveryCard(
                          delivery: delivery,
                          onReject: (id) {
                            setState(() => _dismissedIds.add(id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request dismissed')),
                            );
                          },
                          onAccept: (del) async {
                            if (_accepting) return;
                            _accepting = true;
                            try {
                              final id = (del['_id'] ?? del['id'] ?? '').toString();
                              final success = await ref.read(deliveryProvider.notifier).acceptDelivery(id);
                              if (success && context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.acceptDelivery,
                                  arguments: del,
                                );
                              }
                            } finally {
                              _accepting = false;
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final ValueChanged<String> onReject;
  final ValueChanged<Map<String, dynamic>> onAccept;

  const _DeliveryCard({
    required this.delivery,
    required this.onReject,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final deliveryId = (delivery['_id'] ?? delivery['id'] ?? '').toString();
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final cook = RiderTheme.safeMap(delivery['cookId']) ?? RiderTheme.safeMap(order?['cook']);
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";
    final pickupAddr = delivery['pickupLocation']?['address'] ?? cook?['address'] ?? '45/2 Galle Road, Colombo 03';

    final customer = RiderTheme.safeMap(delivery['customerId']) ?? RiderTheme.safeMap(order?['customer']);
    final custName = customer?['name'] ?? 'Nimal Jayasuriya';
    final dropAddr = delivery['deliveryLocation']?['address'] ?? customer?['address'] ?? '18 Flower Road, Colombo 07';

    final deliveryFee = (delivery['deliveryFee'] as num?)?.toDouble() ?? 450.0;
    final distanceKm = delivery['distanceKm'] ?? 4.2;
    final estMinutes = delivery['estimatedMinutes'] ?? 25;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.deliveryRequestDetails,
            arguments: deliveryId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Order ID, Distance, Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Order #$orderShort',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    'Rs. ${deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: RiderTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badges for Distance and Time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RiderTheme.secondaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me_outlined, size: 14, color: RiderTheme.primaryDark),
                        const SizedBox(width: 4),
                        Text(
                          '$distanceKm km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: RiderTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text(
                          '$estMinutes mins',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Pickup location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFFFF9800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cook: $cookName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          pickupAddr,
                          style: const TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dropoff location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: RiderTheme.secondaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 16, color: RiderTheme.primaryGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dropoff: $custName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          dropAddr,
                          style: const TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons: Accept / Reject
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onReject(deliveryId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RiderTheme.statusRed,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => onAccept(delivery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RiderTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
