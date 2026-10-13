import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../providers/cook_order_provider.dart';
import '../theme/cook_theme.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _safeText(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value.trim().isEmpty ? fallback : value;
    if (value is num || value is bool) return value.toString();
    final map = _safeMap(value);
    if (map != null) {
      final objectId = map[r'$oid'] ?? map['_id'] ?? map['id'] ?? map['value'];
      return objectId == null ? fallback : _safeText(objectId, fallback);
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cookOrderProvider.notifier).fetchOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookOrderProvider);
    final order = state.selectedOrder;

    if (state.isLoading && order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator(color: CookTheme.primaryOrange)),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final orderId = _safeText(order['_id'], widget.orderId);
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId;
    final status = _safeText(order['status'], 'Order Received');
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final customer = _safeMap(order['customer']);
    final customerName = _safeText(customer?['name'], 'Valued Customer');
    final customerPhone = _safeText(customer?['phone'], '+1 555-019-2834');
    final deliveryAddress = _safeText(order['deliveryAddress'], 'Brooklyn Heights, NY');
    final orderNotes = _safeText(order['orderNotes'], 'No special requests provided.');
    final items = (order['items'] as List<dynamic>?) ?? [];
    final createdAt = _safeText(order['createdAt']);
    final timeDisplay = createdAt.length >= 16
        ? '${createdAt.substring(11, 16)} • ${createdAt.substring(0, 10)}'
        : 'Recently';

    final rider = _safeMap(order['rider']);
    final riderName = rider == null ? null : _safeText(rider['name']);
    final riderPhone = rider == null ? null : _safeText(rider['phone']);
    final vehicle = _safeMap(rider?['vehicleDetails']);
    final vehicleModel = vehicle == null ? null : _safeText(vehicle['model'], _safeText(vehicle['type']));

    final isReceived = status == 'Order Received' || status == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Order #$shortId',
          style: const TextStyle(fontWeight: FontWeight.bold, color: CookTheme.textDark, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: CookTheme.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CookTheme.textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CookTheme.getStatusColor(status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(timeDisplay, style: const TextStyle(fontSize: 12, color: CookTheme.textMuted)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: CookTheme.getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: CookTheme.getStatusColor(status),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Customer Details Card
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
                  const Text(
                    'Customer Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: CookTheme.secondaryOrange,
                        child: Icon(Icons.person, color: CookTheme.primaryDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(customerPhone, style: const TextStyle(color: CookTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_outlined, color: CookTheme.primaryOrange),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling customer $customerPhone...')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: CookTheme.primaryOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          deliveryAddress,
                          style: const TextStyle(fontSize: 13, color: CookTheme.textDark, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (riderName != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                  border: Border.all(color: const Color(0xFF20C957), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining, color: Color(0xFF20C957)),
                        const SizedBox(width: 8),
                        const Text(
                          'Assigned Delivery Rider',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FBEF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Rider Assigned', style: TextStyle(color: Color(0xFF20C957), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE8FBEF),
                          child: Text(
                            riderName.isNotEmpty ? riderName[0].toUpperCase() : 'R',
                            style: const TextStyle(color: Color(0xFF20C957), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(riderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (vehicleModel != null)
                                Text(vehicleModel, style: const TextStyle(fontSize: 12, color: CookTheme.textMuted)),
                            ],
                          ),
                        ),
                        if (riderPhone != null)
                          IconButton(
                            icon: const Icon(Icons.phone, color: Color(0xFF20C957)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling rider $riderPhone...')));
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Meals Itemized List
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
                  const Text(
                    'Order Items',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                  ),
                  const SizedBox(height: 14),

                  ...items.map((rawItem) {
                    final item = _safeMap(rawItem) ?? <String, dynamic>{};
                    final qty = item['quantity'] ?? 1;
                    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                    final mealObj = _safeMap(item['meal']);
                    final name = _safeText(item['name'], _safeText(mealObj?['name'], 'Meal Item'));
                    final imageUrl = _safeText(mealObj?['imageUrl'], _safeText(mealObj?['image']));
                    final category = _safeText(mealObj?['category'], 'Fresh');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CookTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: CookTheme.secondaryOrange,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.fastfood,
                                        color: CookTheme.primaryOrange,
                                      ),
                                    )
                                  : const Icon(Icons.fastfood, color: CookTheme.primaryOrange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category,
                                  style: const TextStyle(color: CookTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${AppConstants.currency}${(price * qty).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text('Qty: $qty', style: const TextStyle(color: CookTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 8),

                  // Special Notes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 18, color: CookTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notes: $orderNotes',
                          style: const TextStyle(fontSize: 12, color: CookTheme.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 8),

                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                      ),
                      Text(
                        '${AppConstants.currency}${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CookTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions: Accept / Reject OR Update Order Status
            if (isReceived) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CookTheme.statusRed, width: 1.5),
                        foregroundColor: CookTheme.statusRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () async {
                        await ref.read(cookOrderProvider.notifier).rejectOrder(widget.orderId);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Reject Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CookTheme.statusGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () async {
                        await ref.read(cookOrderProvider.notifier).acceptOrder(widget.orderId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order accepted! Proceed to preparation.'),
                              backgroundColor: CookTheme.statusGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CookTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.updateOrderStatus,
                      arguments: order,
                    );
                  },
                  icon: const Icon(Icons.timeline_rounded),
                  label: const Text(
                    'Manage Order Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
