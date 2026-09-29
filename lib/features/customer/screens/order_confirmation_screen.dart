import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.substring(
      0,
      orderId.length > 8 ? 8 : orderId.length,
    );
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF7A00),
                size: 88,
              ),
              const SizedBox(height: 20),
              Text(
                'Order placed successfully',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Order #$shortId'),
              const SizedBox(height: 8),
              const Text('Estimated delivery: 35-45 minutes'),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.tracking,
                  arguments: orderId,
                ),
                child: const Text('Track Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
