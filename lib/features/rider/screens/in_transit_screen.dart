import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/delivery_provider.dart';
import '../providers/location_provider.dart';
import '../theme/rider_theme.dart';

class InTransitScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> delivery;

  const InTransitScreen({super.key, required this.delivery});

  @override
  ConsumerState<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends ConsumerState<InTransitScreen> {
  int _currentStepIndex = 1; // 0: Picked Up, 1: On Route, 2: Near Customer, 3: Delivered

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = (widget.delivery['_id'] ?? widget.delivery['id'] ?? '').toString();
      if (id.isNotEmpty) {
        ref.read(deliveryProvider.notifier).startDelivery(id);
      }
      ref.read(locationProvider.notifier).startLiveTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final delivery = widget.delivery;
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final customer = RiderTheme.safeMap(delivery['customerId']);
    final custName = customer?['name'] ?? 'Nimal Jayasuriya';
    final custPhone = customer?['phone'] ?? '+94 71 890 1234';
    final dropLoc = RiderTheme.safeMap(delivery['deliveryLocation']);
    final dropAddr = dropLoc?['address'] ??
        customer?['address'] ??
        '18 Flower Road, Colombo 07';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: Text('In Transit · Order #$orderShort'),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded, color: RiderTheme.primaryDark),
            tooltip: 'Full Navigation',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.riderNavigation,
                arguments: delivery,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Delivery Progress Stepper Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Progress',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: RiderTheme.secondaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getStepTitle(_currentStepIndex),
                        style: const TextStyle(
                          color: RiderTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTimeline(),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Map Preview Card
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.riderNavigation,
                arguments: delivery,
              );
            },
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE2EBE4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: RiderTheme.softShadow,
                border: Border.all(color: RiderTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Stack(
                children: [
                  // Stylized Map Background Illustration
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: _MiniMapPainter(),
                      ),
                    ),
                  ),

                  // Map Overlay Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Info Badge on Map
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: RiderTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: RiderTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live GPS · ${locationState.distanceRemainingKm} km (${locationState.etaMinutes} min)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Open Navigation Button
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.riderNavigation,
                          arguments: delivery,
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Open Navigation', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RiderTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Customer Details Card
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
                  'Customer Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: RiderTheme.secondaryGreen,
                      child: const Icon(Icons.person, color: RiderTheme.primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            custName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            custPhone,
                            style: const TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.call, color: RiderTheme.primaryGreen),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling customer $custPhone...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address', style: TextStyle(fontSize: 12, color: RiderTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(dropAddr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.speaker_notes_outlined, size: 18, color: Color(0xFFF57F17)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Ring doorbell twice or call at the front gate.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Advance Step or Complete Delivery Buttons
          if (_currentStepIndex < 2)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentStepIndex = 2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated: Near Customer Location')),
                  );
                },
                icon: const Icon(Icons.near_me_rounded, color: RiderTheme.primaryDark),
                label: const Text(
                  'Mark: Near Customer Location',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RiderTheme.primaryDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RiderTheme.primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          if (_currentStepIndex >= 2) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.riderDeliveryConfirmation,
                    arguments: delivery,
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: const Text(
                  'Arrived at Customer · Confirm Delivery',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'PICKED UP';
      case 1:
        return 'ON ROUTE';
      case 2:
        return 'NEAR CUSTOMER';
      case 3:
        return 'DELIVERED';
      default:
        return 'IN TRANSIT';
    }
  }

  Widget _buildTimeline() {
    final steps = ['Picked Up', 'On Route', 'Near Customer', 'Delivered'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          final isPassed = lineIndex < _currentStepIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: isPassed ? RiderTheme.primaryGreen : const Color(0xFFE0E0E0),
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final isCompleted = stepIdx < _currentStepIndex;
        final isCurrent = stepIdx == _currentStepIndex;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? RiderTheme.primaryGreen
                    : (isCurrent ? Colors.white : const Color(0xFFF0F0F0)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isCompleted || isCurrent) ? RiderTheme.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : (isCurrent
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: RiderTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Text(
                            '${stepIdx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          )),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIdx],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? RiderTheme.primaryDark : RiderTheme.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = const Color(0xFFE8EFEA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), land);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), road);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), road);

    final route = Paint()
      ..color = RiderTheme.primaryGreen
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.85);
    canvas.drawPath(path, route);

    // Rider dot
    final rider = Paint()..color = RiderTheme.primaryGreen;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.6), 7, rider);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
