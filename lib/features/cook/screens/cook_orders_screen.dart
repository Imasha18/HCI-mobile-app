import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../providers/cook_order_provider.dart';
import '../theme/cook_theme.dart';

class CookOrdersScreen extends ConsumerStatefulWidget {
  const CookOrdersScreen({super.key});

  @override
  ConsumerState<CookOrdersScreen> createState() => _CookOrdersScreenState();
}

class _CookOrdersScreenState extends ConsumerState<CookOrdersScreen> {
  final List<String> _filters = [
    'All',
    'Order Received',
    'Accepted',
    'Preparing',
    'Ready For Pickup',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cookOrderProvider.notifier).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookOrderProvider);
    final selectedFilter = state.selectedFilter;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Incoming Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CookTheme.textDark,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: CookTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(cookOrderProvider.notifier).fetchOrders(
                selectedFilter == 'All' ? null : selectedFilter,
              );
        },
        child: Column(
          children: [
            // Filter Status Tabs
            Container(
              height: 54,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(cookOrderProvider.notifier).filterOrders(filter);
                    },
                    selectedColor: CookTheme.primaryOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : CookTheme.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: CookTheme.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? CookTheme.primaryOrange : Colors.grey.shade300,
                      ),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),

            // Orders list
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: CookTheme.primaryOrange),
                    )
                  : state.orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No orders in this category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CookTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'When customers place orders, they will show up here.',
                                style: TextStyle(color: CookTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.orders.length,
                          itemBuilder: (context, index) {
                            final order = state.orders[index] as Map<String, dynamic>;
                            final orderId = order['_id'] as String? ?? '';
                            final shortId = orderId.length > 6
                                ? orderId.substring(orderId.length - 6).toUpperCase()
                                : orderId;
                            final customer = order['customer'] as Map<String, dynamic>?;
                            final customerName = customer?['name'] as String? ?? 'Customer';
                            final total = (order['total'] as num?)?.toDouble() ?? 0.0;
                            final status = (order['status'] as String?) ?? 'Order Received';
                            final items = (order['items'] as List<dynamic>?) ?? [];
                            final createdAt = order['createdAt'] as String?;
                            final timeDisplay = createdAt != null && createdAt.length >= 16
                                ? '${createdAt.substring(11, 16)} • ${createdAt.substring(0, 10)}'
                                : 'Just now';

                            final isPendingApproval = status == 'Order Received' || status == 'pending';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: CookTheme.softShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top card bar
                                  InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.cookOrderDetails,
                                        arguments: orderId,
                                      );
                                    },
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: CookTheme.surfaceLight,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.grey.shade300),
                                                    ),
                                                    child: Text(
                                                      '#$shortId',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: CookTheme.textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    timeDisplay,
                                                    style: const TextStyle(fontSize: 12, color: CookTheme.textMuted),
                                                  ),
                                                ],
                                              ),
                                              // Status badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: CookTheme.getStatusBgColor(status),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: CookTheme.getStatusColor(status),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                customerName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: CookTheme.textDark,
                                                ),
                                              ),
                                              Text(
                                                '${AppConstants.currency}${total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: CookTheme.primaryDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Meals List preview
                                          ...items.map((item) {
                                            final qty = item['quantity'] ?? 1;
                                            final mealObj = item['meal'] as Map<String, dynamic>?;
                                            final mName = item['name'] ?? mealObj?['name'] ?? 'Meal item';
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Text(
                                                '• $qty × $mName',
                                                style: const TextStyle(fontSize: 13, color: CookTheme.textMuted),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),

                                  // Action Buttons
                                  if (isPendingApproval) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              await ref.read(cookOrderProvider.notifier).acceptOrder(orderId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Order Accepted!'),
                                                    backgroundColor: CookTheme.statusGreen,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.check_circle_outline, color: CookTheme.statusGreen),
                                            label: const Text(
                                              'Accept Order',
                                              style: TextStyle(
                                                color: CookTheme.statusGreen,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, height: 28, color: const Color(0xFFF0F0F0)),
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              await ref.read(cookOrderProvider.notifier).rejectOrder(orderId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Order Rejected'),
                                                    backgroundColor: CookTheme.statusRed,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.cancel_outlined, color: CookTheme.statusRed),
                                            label: const Text(
                                              'Reject',
                                              style: TextStyle(
                                                color: CookTheme.statusRed,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.cookOrderDetails,
                                          arguments: orderId,
                                        );
                                      },
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'View Details & Update Status',
                                              style: TextStyle(
                                                color: CookTheme.primaryDark,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(Icons.arrow_forward_rounded, size: 16, color: CookTheme.primaryDark),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
