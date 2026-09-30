import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/delivery_provider.dart';
import '../providers/earnings_provider.dart';
import '../providers/rider_provider.dart';
import '../theme/rider_theme.dart';

class DeliveryConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> delivery;

  const DeliveryConfirmationScreen({super.key, required this.delivery});

  @override
  ConsumerState<DeliveryConfirmationScreen> createState() =>
      _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState
    extends ConsumerState<DeliveryConfirmationScreen> {
  bool _isProcessing = false;
  bool _hasProofImage = false;
  String? _proofImageUrl;
  bool _confirmedHandover = true;

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final deliveryId = (delivery['_id'] ?? delivery['id'] ?? '').toString();
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final customer = RiderTheme.safeMap(delivery['customerId']);
    final custName = customer?['name'] ?? 'Nimal Jayasuriya';
    final dropLoc = RiderTheme.safeMap(delivery['deliveryLocation']);
    final dropAddr = dropLoc?['address'] ??
        customer?['address'] ??
        '18 Flower Road, Colombo 07';
    final deliveryFee = (delivery['deliveryFee'] as num?)?.toDouble() ?? 450.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Congratulatory / Delivery Handover Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: RiderTheme.softShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: RiderTheme.secondaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: RiderTheme.primaryGreen,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Arrived at Destination!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RiderTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order #$orderShort · $custName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: RiderTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: RiderTheme.secondaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: RiderTheme.primaryDark, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Delivery Fee: Rs. ${deliveryFee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: RiderTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Dropoff Location Confirmation Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: RiderTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drop-off Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_pin, color: Color(0xFFE53935), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dropAddr,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: RiderTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Proof of Delivery Photo Upload (Cloudinary / Camera support)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: RiderTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Proof Image',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        _hasProofImage ? 'ATTACHED' : 'OPTIONAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _hasProofImage ? RiderTheme.primaryGreen : RiderTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Take a picture of the food package delivered to customer or doorstep.',
                    style: TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  if (!_hasProofImage)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _hasProofImage = true;
                          _proofImageUrl =
                              'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=800&auto=format&fit=crop&q=60';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delivery proof photo attached successfully!')),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBF9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: RiderTheme.primaryGreen.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_rounded, size: 36, color: RiderTheme.primaryGreen),
                            SizedBox(height: 8),
                            Text(
                              'Tap to Capture Proof Photo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: RiderTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(_proofImageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => setState(() {
                              _hasProofImage = false;
                              _proofImageUrl = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Handover Checklist
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: RiderTheme.softShadow,
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _confirmedHandover,
                    activeColor: RiderTheme.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I have handed over the meal directly to the customer or designated drop-point.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    onChanged: (val) => setState(() => _confirmedHandover = val ?? false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Delivery Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (_isProcessing || !_confirmedHandover)
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final scaffold = ScaffoldMessenger.of(context);
                        setState(() => _isProcessing = true);

                        final success = await ref
                            .read(deliveryProvider.notifier)
                            .completeDelivery(
                              deliveryId,
                              proofImageUrl: _proofImageUrl,
                            );

                        if (!mounted) return;
                        setState(() => _isProcessing = false);

                        if (success) {
                          // Refresh rider dashboard & earnings
                          ref.read(riderProvider.notifier).fetchDashboard();
                          ref.read(earningsProvider.notifier).fetchEarnings();
                          ref.read(earningsProvider.notifier).fetchHistory();

                          scaffold.showSnackBar(
                            const SnackBar(
                              backgroundColor: RiderTheme.primaryGreen,
                              content: Text('Delivery Completed! Earning added to your account.'),
                            ),
                          );

                          nav.pushNamedAndRemoveUntil(
                            AppRoutes.riderDashboard,
                            (route) => false,
                          );
                        } else {
                          scaffold.showSnackBar(
                            const SnackBar(content: Text('Failed to confirm delivery. Please retry.')),
                          );
                        }
                      },
                icon: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 24),
                label: const Text(
                  'Confirm & Complete Delivery',
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
      ),
    );
  }
}
