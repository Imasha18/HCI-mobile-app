import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/cook_order_provider.dart';
import '../theme/cook_theme.dart';

class UpdateOrderStatusScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const UpdateOrderStatusScreen({super.key, required this.order});

  @override
  ConsumerState<UpdateOrderStatusScreen> createState() => _UpdateOrderStatusScreenState();
}

class _UpdateOrderStatusScreenState extends ConsumerState<UpdateOrderStatusScreen> {
  final List<String> _timelineSteps = [
    'Order Received',
    'Accepted',
    'Preparing',
    'Ready For Pickup',
    'Completed',
  ];

  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = (widget.order['status'] as String?) ?? 'Order Received';
  }

  int get _currentStepIndex {
    final idx = _timelineSteps.indexOf(_currentStatus);
    return idx != -1 ? idx : 0;
  }

  Future<void> _updateStatus(String nextStatus) async {
    setState(() => _isUpdating = true);
    final orderId = widget.order['_id'] as String;

    final success = await ref.read(cookOrderProvider.notifier).updateStatus(orderId, nextStatus);

    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (success) _currentStatus = nextStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Order updated to $nextStatus' : 'Failed to update order status'),
          backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['_id'] as String;
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId;
    final customer = widget.order['customer'] as Map<String, dynamic>?;
    final customerName = customer?['name'] as String? ?? 'Customer';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Manage Order #$shortId',
          style: const TextStyle(fontWeight: FontWeight.bold, color: CookTheme.textDark, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Highlight Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: CookTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CookTheme.getStatusBgColor(_currentStatus),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: CookTheme.getStatusColor(_currentStatus),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Order Stage',
                          style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentStatus,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CookTheme.getStatusColor(_currentStatus),
                          ),
                        ),
                        Text('Customer: $customerName', style: const TextStyle(fontSize: 13, color: CookTheme.textDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Timeline Card
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
                    'Order Progress Timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                  ),
                  const SizedBox(height: 20),

                  ...List.generate(_timelineSteps.length, (index) {
                    final step = _timelineSteps[index];
                    final isCompleted = index <= _currentStepIndex;
                    final isCurrent = index == _currentStepIndex;
                    final isLast = index == _timelineSteps.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicator circle & connecting line
                        Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? CookTheme.statusGreen : Colors.grey.shade200,
                                border: Border.all(
                                  color: isCurrent ? CookTheme.primaryOrange : (isCompleted ? CookTheme.statusGreen : Colors.grey.shade300),
                                  width: isCurrent ? 3 : 1,
                                ),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 36,
                                color: index < _currentStepIndex ? CookTheme.statusGreen : Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Text label & description
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    color: isCompleted ? CookTheme.textDark : Colors.grey.shade400,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Active step in kitchen workflow',
                                    style: TextStyle(fontSize: 12, color: CookTheme.primaryDark),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              'Update Status Action',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CookTheme.textDark),
            ),
            const SizedBox(height: 12),

            // Button: Start Preparing
            if (_currentStatus == 'Accepted' || _currentStatus == 'Order Received')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CookTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            await _updateStatus('Preparing');
                            if (context.mounted) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.preparingOrder,
                                arguments: widget.order,
                              );
                            }
                          },
                    icon: const Icon(Icons.soup_kitchen_rounded),
                    label: const Text('Start Preparing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),

            // Button: Open Interactive Cooking Checklist & Timer
            if (_currentStatus == 'Preparing') ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CookTheme.primaryDark,
                      side: const BorderSide(color: CookTheme.primaryOrange, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.preparingOrder,
                        arguments: widget.order,
                      );
                    },
                    icon: const Icon(Icons.checklist_rtl_rounded),
                    label: const Text('Open Kitchen Checklist & Timer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CookTheme.statusGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isUpdating ? null : () => _updateStatus('Ready For Pickup'),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Ready For Pickup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],

            // Button: Complete
            if (_currentStatus == 'Ready For Pickup')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CookTheme.statusGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isUpdating ? null : () => _updateStatus('Completed'),
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),

            if (_currentStatus == 'Completed')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CookTheme.statusGreenBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: CookTheme.statusGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This order has been successfully cooked, packed, and fulfilled.',
                        style: TextStyle(color: CookTheme.statusGreen, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
