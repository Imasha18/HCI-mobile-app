import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../theme/rider_theme.dart';

class AcceptDeliveryScreen extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const AcceptDeliveryScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final cook = RiderTheme.safeMap(delivery['cookId']);
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";
    final cookPhone = cook?['phone'] ?? '+94 77 234 5678';
    final pickupLoc = RiderTheme.safeMap(delivery['pickupLocation']);
    final pickupAddr = pickupLoc?['address'] ?? cook?['address'] ?? '45/2 Galle Road, Colombo 03';
    final deliveryFee = (delivery['deliveryFee'] as num?)?.toDouble() ?? 450.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Delivery Assigned'),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon Circle
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: RiderTheme.secondaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: RiderTheme.primaryGreen,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Delivery Assigned!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: RiderTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #$orderShort is now assigned to you.\nPlease head to the kitchen to collect the meal.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: RiderTheme.textMuted, height: 1.4),
              ),

              const SizedBox(height: 32),

              // Pickup Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RiderTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 22, color: Color(0xFFFF9800)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cookName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pickupAddr,
                                style: const TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cook Phone', style: TextStyle(color: RiderTheme.textMuted)),
                        Text(cookPhone, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Delivery Earning', style: TextStyle(color: RiderTheme.textMuted)),
                        Text('Rs. ${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: RiderTheme.primaryDark, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Start Pickup Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.riderPickup,
                      arguments: delivery,
                    );
                  },
                  icon: const Icon(Icons.directions_bike_rounded, size: 22),
                  label: const Text(
                    'Start Pickup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RiderTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.riderDashboard),
                child: const Text('Back to Dashboard', style: TextStyle(color: RiderTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
