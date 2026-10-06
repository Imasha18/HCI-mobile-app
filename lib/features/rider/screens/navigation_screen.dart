import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/location_provider.dart';
import '../theme/rider_theme.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> delivery;

  const NavigationScreen({super.key, required this.delivery});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start simulated live GPS updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).startLiveTracking();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final delivery = widget.delivery;

    final cook = RiderTheme.safeMap(delivery['cookId']);
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";
    final cookPhone = cook?['phone'] ?? '+94 77 234 5678';
    final pickupLoc = RiderTheme.safeMap(delivery['pickupLocation']);
    final pickupAddr =
        pickupLoc?['address'] ?? cook?['address'] ?? '45/2 Galle Road, Colombo 03';

    final customer = RiderTheme.safeMap(delivery['customerId']);
    final custName = customer?['name'] ?? 'Nimal Jayasuriya';
    final custPhone = customer?['phone'] ?? '+94 71 890 1234';
    final dropLoc = RiderTheme.safeMap(delivery['deliveryLocation']);
    final dropAddr = dropLoc?['address'] ??
        customer?['address'] ??
        '18 Flower Road, Colombo 07';

    final isEnRouteToCook = delivery['status'] == 'ACCEPTED';
    final targetName = isEnRouteToCook ? cookName : custName;
    final targetAddress = isEnRouteToCook ? pickupAddr : dropAddr;
    final targetPhone = isEnRouteToCook ? cookPhone : custPhone;

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE9),
      body: Stack(
        children: [
          // Interactive Custom Painted Map
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: () => setState(() => _zoomLevel = (_zoomLevel >= 1.4 ? 1.0 : 1.4)),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MapCanvasPainter(
                      pulseValue: _pulseController.value,
                      zoom: _zoomLevel,
                      riderHeading: locationState.heading,
                    ),
                  );
                },
              ),
            ),
          ),

          // Map Control Overlays (Top Floating Maneuver Box)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: RiderTheme.softShadow,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: RiderTheme.textDark),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: RiderTheme.primaryDark,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: RiderTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: RiderTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'In 250m, Turn Right',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'Onto Galle Road (A2)',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${locationState.speedKmh.toStringAsFixed(0)} km/h',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Zoom & Recenter Floating Action Buttons
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  backgroundColor: Colors.white,
                  foregroundColor: RiderTheme.textDark,
                  onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 1.8)),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: Colors.white,
                  foregroundColor: RiderTheme.textDark,
                  onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 1.8)),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: RiderTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    setState(() => _zoomLevel = 1.0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Re-centered to live GPS position'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // Bottom Navigation Summary Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance & ETA Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: RiderTheme.secondaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: RiderTheme.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  '${locationState.etaMinutes} mins',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: RiderTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${locationState.distanceRemainingKm} km remaining',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: RiderTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEnRouteToCook ? 'TO KITCHEN' : 'TO CUSTOMER',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: RiderTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Destination Details
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isEnRouteToCook ? const Color(0xFFFFF3E0) : RiderTheme.secondaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEnRouteToCook ? Icons.soup_kitchen_rounded : Icons.person_pin_circle_rounded,
                          color: isEnRouteToCook ? const Color(0xFFFF9800) : RiderTheme.primaryGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              targetAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call_rounded, color: Color(0xFF1565C0)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling $targetPhone...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isEnRouteToCook) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.riderPickup,
                            arguments: delivery,
                          );
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.riderDeliveryConfirmation,
                            arguments: delivery,
                          );
                        }
                      },
                      icon: Icon(
                        isEnRouteToCook ? Icons.store_rounded : Icons.check_circle_outline_rounded,
                        size: 22,
                      ),
                      label: Text(
                        isEnRouteToCook ? 'I Have Reached The Kitchen' : 'Arrived at Customer Location',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
          ),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final double pulseValue;
  final double zoom;
  final double riderHeading;

  _MapCanvasPainter({
    required this.pulseValue,
    required this.zoom,
    required this.riderHeading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background map land
    final landPaint = Paint()..color = const Color(0xFFF4F6F4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    // Green parks
    final parkPaint = Paint()..color = const Color(0xFFE2F3E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, size.height * 0.15, 120, 100), const Radius.circular(24)),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.65, size.height * 0.45, 100, 140), const Radius.circular(24)),
      parkPaint,
    );

    // Lake / Waterway
    final waterPaint = Paint()
      ..color = const Color(0xFFD6E9F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    final waterPath = Path();
    waterPath.moveTo(0, size.height * 0.65);
    waterPath.quadraticBezierTo(size.width * 0.4, size.height * 0.75, size.width, size.height * 0.60);
    canvas.drawPath(waterPath, waterPaint);

    // Road network
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * zoom
      ..strokeCap = StrokeCap.round;
    final roadBorder = Paint()
      ..color = const Color(0xFFD0D7D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * zoom
      ..strokeCap = StrokeCap.round;

    final mainRoad = Path();
    mainRoad.moveTo(size.width * 0.2, size.height * 0.1);
    mainRoad.lineTo(size.width * 0.35, size.height * 0.35);
    mainRoad.lineTo(size.width * 0.5, size.height * 0.5);
    mainRoad.lineTo(size.width * 0.7, size.height * 0.7);

    canvas.drawPath(mainRoad, roadBorder);
    canvas.drawPath(mainRoad, roadPaint);

    // Secondary cross roads
    final crossRoad = Path();
    crossRoad.moveTo(size.width * 0.05, size.height * 0.4);
    crossRoad.lineTo(size.width * 0.95, size.height * 0.4);
    canvas.drawPath(crossRoad, roadPaint);

    // Active Navigation Route (Green Glow + Line)
    final routeGlowPaint = Paint()
      ..color = RiderTheme.primaryGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16 * zoom
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = RiderTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * zoom
      ..strokeCap = StrokeCap.round;

    final activeRoute = Path();
    activeRoute.moveTo(size.width * 0.25, size.height * 0.25); // Cook Kitchen
    activeRoute.lineTo(size.width * 0.35, size.height * 0.35);
    activeRoute.lineTo(size.width * 0.5, size.height * 0.5); // Current Rider
    activeRoute.lineTo(size.width * 0.7, size.height * 0.7); // Customer Dropoff

    canvas.drawPath(activeRoute, routeGlowPaint);
    canvas.drawPath(activeRoute, routePaint);

    // 1. Cook Kitchen Marker (Origin)
    final cookOffset = Offset(size.width * 0.25, size.height * 0.25);
    final cookPaint = Paint()..color = const Color(0xFFFF9800);
    canvas.drawCircle(cookOffset, 16 * zoom, cookPaint);
    final cookInner = Paint()..color = Colors.white;
    canvas.drawCircle(cookOffset, 8 * zoom, cookInner);

    // 2. Customer Destination Marker (Dropoff)
    final custOffset = Offset(size.width * 0.7, size.height * 0.7);
    final custPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawCircle(custOffset, 16 * zoom, custPaint);
    final custInner = Paint()..color = Colors.white;
    canvas.drawCircle(custOffset, 8 * zoom, custInner);

    // 3. Live Rider GPS Position (Pulsing Green Halo)
    final riderOffset = Offset(size.width * 0.5, size.height * 0.5);
    final pulseRadius = (16 + (14 * pulseValue)) * zoom;
    final pulsePaint = Paint()
      ..color = RiderTheme.primaryGreen.withValues(alpha: (1.0 - pulseValue).clamp(0.0, 1.0) * 0.5);
    canvas.drawCircle(riderOffset, pulseRadius, pulsePaint);

    final riderPaint = Paint()..color = RiderTheme.primaryDark;
    canvas.drawCircle(riderOffset, 14 * zoom, riderPaint);

    // Arrow pointer
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final arrowPath = Path();
    final arrowAngle = riderHeading * math.pi / 180;
    arrowPath.moveTo(
      riderOffset.dx + 8 * math.cos(arrowAngle),
      riderOffset.dy + 8 * math.sin(arrowAngle),
    );
    arrowPath.lineTo(
      riderOffset.dx + 6 * math.cos(arrowAngle + 2.4),
      riderOffset.dy + 6 * math.sin(arrowAngle + 2.4),
    );
    arrowPath.lineTo(
      riderOffset.dx,
      riderOffset.dy,
    );
    arrowPath.lineTo(
      riderOffset.dx + 6 * math.cos(arrowAngle - 2.4),
      riderOffset.dy + 6 * math.sin(arrowAngle - 2.4),
    );
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.zoom != zoom ||
        oldDelegate.riderHeading != riderHeading;
  }
}
