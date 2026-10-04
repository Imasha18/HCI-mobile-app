import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/delivery_provider.dart';
import '../theme/rider_theme.dart';

class PickupScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> delivery;

  const PickupScreen({super.key, required this.delivery});

  @override
  ConsumerState<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends ConsumerState<PickupScreen> {
  bool _reachedCook = false;
  bool _isProcessing = false;
  final Set<int> _checkedItems = {};
  late Map<String, dynamic> _delivery;

  @override
  void initState() {
    super.initState();
    _delivery = Map<String, dynamic>.from(widget.delivery);
    final deliveryId = (_delivery['_id'] ?? _delivery['id'] ?? '').toString();
    if (deliveryId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(deliveryProvider.notifier).fetchDeliveryDetails(deliveryId).then((fresh) {
          if (fresh != null && mounted) {
            setState(() => _delivery = fresh);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;
    final deliveryId = (delivery['_id'] ?? delivery['id'] ?? '').toString();
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final cook = RiderTheme.safeMap(delivery['cookId']);
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";
    final cookPhone = cook?['phone'] ?? '+94 77 234 5678';
    final pickupLoc = RiderTheme.safeMap(delivery['pickupLocation']);
    final pickupAddr = pickupLoc?['address'] ?? cook?['address'] ?? '45/2 Galle Road, Colombo 03';

    final items = (order?['items'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text('Pickup from Cook'),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order ID and Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderShort',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _reachedCook ? RiderTheme.secondaryGreen : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _reachedCook ? 'AT KITCHEN' : 'EN ROUTE TO COOK',
                  style: TextStyle(
                    color: _reachedCook ? RiderTheme.primaryDark : const Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cook Kitchen Details Card
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
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.soup_kitchen_rounded, color: Color(0xFFFF9800), size: 26),
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
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling cook at $cookPhone...')),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFFFF9800)),
                        label: const Text('Call Cook', style: TextStyle(color: RiderTheme.textDark)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF9800)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.riderNavigation, arguments: delivery);
                        },
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RiderTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order Items Checklist
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
                  'Verify Order Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check off each item with the cook before leaving.',
                  style: TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                ),
                const SizedBox(height: 12),
                if (items.isNotEmpty)
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final itemMap = RiderTheme.safeMap(entry.value);
                    final meal = RiderTheme.safeMap(itemMap?['meal']);
                    final name = itemMap?['name'] ?? meal?['name'] ?? 'Home meal';
                    final qty = itemMap?['quantity'] ?? 1;
                    final isChecked = _checkedItems.contains(idx);

                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: RiderTheme.primaryGreen,
                      title: Text('$qty × $name', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Freshly packed & sealed', style: TextStyle(fontSize: 12, color: Colors.green)),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _checkedItems.add(idx);
                          } else {
                            _checkedItems.remove(idx);
                          }
                        });
                      },
                    );
                  })
                else ...[
                  CheckboxListTile(
                    value: _checkedItems.contains(0),
                    activeColor: RiderTheme.primaryGreen,
                    title: const Text('2 × Authentic Sri Lankan Lamprais', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Banana leaf sealed packet', style: TextStyle(fontSize: 12, color: Colors.green)),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedItems.add(0);
                        } else {
                          _checkedItems.remove(0);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: _checkedItems.contains(1),
                    activeColor: RiderTheme.primaryGreen,
                    title: const Text('1 × Spicy Chicken Cheese Kottu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Hot insulated packaging', style: TextStyle(fontSize: 12, color: Colors.green)),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedItems.add(1);
                        } else {
                          _checkedItems.remove(1);
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reached Cook Toggle Button
          if (!_reachedCook)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _reachedCook = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked: Reached cook kitchen')),
                  );
                },
                icon: const Icon(Icons.pin_drop_rounded, color: RiderTheme.primaryDark),
                label: const Text(
                  'Reached Cook Kitchen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RiderTheme.primaryDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RiderTheme.primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          if (_reachedCook) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        setState(() => _isProcessing = true);
                        final success = await ref.read(deliveryProvider.notifier).pickupDelivery(deliveryId);
                        if (!mounted) return;
                        if (success) {
                          nav.pushReplacementNamed(
                            AppRoutes.riderInTransit,
                            arguments: delivery,
                          );
                        } else {
                          setState(() => _isProcessing = false);
                        }
                      },
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.takeout_dining_rounded, size: 22),
                label: const Text(
                  'Picked Up Food (Start Delivery)',
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
        ],
      ),
    );
  }
}
