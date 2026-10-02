import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cook_order_provider.dart';
import '../theme/cook_theme.dart';

class PreparingOrderScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const PreparingOrderScreen({super.key, required this.order});

  @override
  ConsumerState<PreparingOrderScreen> createState() => _PreparingOrderScreenState();
}

class _PreparingOrderScreenState extends ConsumerState<PreparingOrderScreen> {
  int _secondsRemaining = 25 * 60; // 25 minutes default timer
  Timer? _timer;
  bool _isRunning = true;

  final Map<String, bool> _checklist = {
    'Wash ingredients': true,
    'Prepare ingredients': false,
    'Cook meal': false,
    'Pack meal': false,
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && _isRunning) {
        setState(() => _secondsRemaining--);
      } else if (_secondsRemaining == 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final completedCount = _checklist.values.where((v) => v).length;
    return completedCount / _checklist.length;
  }

  Future<void> _markReadyForPickup() async {
    final orderId = widget.order['_id'] as String;
    final success = await ref.read(cookOrderProvider.notifier).updateStatus(orderId, 'Ready For Pickup');
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order is marked Ready For Pickup! Delivery rider notified.'),
            backgroundColor: CookTheme.statusGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['_id'] as String;
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Preparing Order #$shortId',
          style: const TextStyle(fontWeight: FontWeight.bold, color: CookTheme.textDark, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preparation Countdown Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CookTheme.primaryOrange, Color(0xFFFF8A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: CookTheme.elevatedShadow,
              ),
              child: Column(
                children: [
                  const Text(
                    'ESTIMATED PREPARATION TIME',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _isRunning = !_isRunning),
                        icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.25)),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _secondsRemaining += 5 * 60),
                        icon: const Icon(Icons.add_alarm_rounded),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.25)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress Indicator Bar
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: CookTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kitchen Progress',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}% Done',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: CookTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: CookTheme.secondaryOrange,
                      color: CookTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Checklist Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: CookTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preparation Checklist',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                  ),
                  const SizedBox(height: 12),

                  ..._checklist.keys.map((task) {
                    final isChecked = _checklist[task] ?? false;
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        task,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isChecked ? CookTheme.textDark : CookTheme.textMuted,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      value: isChecked,
                      activeColor: CookTheme.statusGreen,
                      onChanged: (val) {
                        setState(() {
                          _checklist[task] = val ?? false;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Action Button: Ready For Pickup
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CookTheme.statusGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _markReadyForPickup,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Ready For Pickup',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
