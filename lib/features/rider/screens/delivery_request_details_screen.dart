import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/delivery_provider.dart';
import '../theme/rider_theme.dart';

class DeliveryRequestDetailsScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const DeliveryRequestDetailsScreen({super.key, required this.deliveryId});

  @override
  ConsumerState<DeliveryRequestDetailsScreen> createState() => _DeliveryRequestDetailsScreenState();
}

class _DeliveryRequestDetailsScreenState extends ConsumerState<DeliveryRequestDetailsScreen> {
  Map<String, dynamic>? _delivery;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final data = await ref.read(deliveryProvider.notifier).fetchDeliveryDetails(widget.deliveryId);
    if (mounted) {
      setState(() {
        _delivery = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Details')),
        body: const Center(
          child: CircularProgressIndicator(color: RiderTheme.primaryGreen),
        ),
      );
    }

    if (_delivery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Delivery request not found.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final delivery = _delivery!;
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final cook = RiderTheme.safeMap(delivery['cookId']);
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";
    final cookPhone = cook?['phone'] ?? '+94 77 234 5678';
    final pickupLoc = RiderTheme.safeMap(delivery['pickupLocation']);
    final pickupAddr = pickupLoc?['address'] ?? cook?['address'] ?? '45/2 Galle Road, Colombo 03';

    final customer = RiderTheme.safeMap(delivery['customerId']);
    final custName = customer?['name'] ?? 'Nimal Jayasuriya';
    final custPhone = customer?['phone'] ?? '+94 71 890 1234';
    final dropLoc = RiderTheme.safeMap(delivery['deliveryLocation']);
    final dropAddr = dropLoc?['address'] ?? customer?['address'] ?? '18 Flower Road, Colombo 07';

    final deliveryFee = (delivery['deliveryFee'] as num?)?.toDouble() ?? 450.0;
    final distanceKm = delivery['distanceKm'] ?? 4.2;
    final estMinutes = delivery['estimatedMinutes'] ?? 25;

    final items = (order?['items'] as List<dynamic>?) ?? [];
    final orderTotal = (order?['total'] as num?)?.toDouble() ?? (deliveryFee * 3);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: Text('Order #$orderShort'),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Fee & Earnings Highlight Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF20C957), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: RiderTheme.elevatedShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Delivery Earning',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${deliveryFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$distanceKm km',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '~$estMinutes min',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Route: Cook & Customer Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: RiderTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Route',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Pickup Cook Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFFFF9800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PICKUP LOCATION', style: TextStyle(fontSize: 11, color: RiderTheme.textMuted, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(cookName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(pickupAddr, style: const TextStyle(color: RiderTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Phone: $cookPhone', style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800))),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 4, bottom: 4),
                  child: SizedBox(
                    height: 24,
                    child: VerticalDivider(color: Color(0xFFBDBDBD), thickness: 1.5),
                  ),
                ),

                // Delivery Customer Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: RiderTheme.secondaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, size: 20, color: RiderTheme.primaryGreen),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DELIVERY LOCATION', style: TextStyle(fontSize: 11, color: RiderTheme.textMuted, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(custName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(dropAddr, style: const TextStyle(color: RiderTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Phone: $custPhone', style: const TextStyle(fontSize: 12, color: RiderTheme.primaryDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Meal Items Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: RiderTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Meal Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (items.isNotEmpty)
                  ...items.map((item) {
                    final itemMap = RiderTheme.safeMap(item);
                    final meal = RiderTheme.safeMap(itemMap?['meal']);
                    final name = itemMap?['name'] ?? meal?['name'] ?? 'Home-cooked dish';
                    final qty = itemMap?['quantity'] ?? 1;
                    final price = (itemMap?['price'] as num?)?.toDouble() ?? 750.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$qty × $name', style: const TextStyle(fontSize: 14)),
                          Text('Rs. ${(price * qty).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  })
                else ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2 × Authentic Sri Lankan Lamprais', style: TextStyle(fontSize: 14)),
                      Text('Rs. 2,900.00', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 × Spicy Chicken Cheese Kottu', style: TextStyle(fontSize: 14)),
                      Text('Rs. 1,250.00', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Status', style: TextStyle(color: RiderTheme.textMuted)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RiderTheme.secondaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PAID ONLINE', style: TextStyle(color: RiderTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Food Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rs. ${orderTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Accept Delivery Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await ref.read(deliveryProvider.notifier).acceptDelivery(widget.deliveryId);
                if (success && context.mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.acceptDelivery,
                    arguments: delivery,
                  );
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: const Text(
                'Accept Delivery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
