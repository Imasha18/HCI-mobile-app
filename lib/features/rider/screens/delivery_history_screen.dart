import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/earnings_provider.dart';
import '../theme/rider_theme.dart';

class DeliveryHistoryScreen extends ConsumerStatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  ConsumerState<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends ConsumerState<DeliveryHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsProvider);
    final history = earningsState.history;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'Delivery History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
        actions: [
          if (history.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'clear') {
                  _confirmClearHistory(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                        color: Color(0xFFE53935),
                      ),
                      SizedBox(width: 10),
                      Text('Clear history'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(earningsProvider.notifier).fetchHistory(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: RiderTheme.primaryGreen,
        onRefresh: () => ref.read(earningsProvider.notifier).fetchHistory(),
        child: history.isEmpty
            ? _buildSampleOrEmpty(context)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final id = (item['_id'] ?? item['id'] ?? '').toString();
                  return Dismissible(
                    key: ValueKey(id.isEmpty ? 'delivery-history-$index' : id),
                    direction: id.isEmpty
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: _buildDeleteBackground(),
                    confirmDismiss: (_) async {
                      await _confirmRemoveHistoryItem(context, id);
                      return false;
                    },
                    child: _DeliveryHistoryCard(
                      delivery: item,
                      onDelete: id.isEmpty
                          ? null
                          : () => _confirmRemoveHistoryItem(context, id),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }

  Future<bool> _confirmRemoveHistoryItem(
    BuildContext context,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove delivery?'),
        content: const Text(
          'This removes the delivery from your history view. Your earnings are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    final removed =
        await ref.read(earningsProvider.notifier).removeHistoryItem(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removed
                ? 'Delivery removed from history'
                : 'Unable to remove delivery',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return removed;
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear delivery history?'),
        content: const Text(
          'This clears the history view. Your earnings are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cleared = await ref.read(earningsProvider.notifier).clearHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleared
              ? 'Delivery history cleared'
              : 'Unable to clear delivery history',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSampleOrEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: RiderTheme.secondaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_outlined,
                size: 40,
                color: RiderTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No delivery history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RiderTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed deliveries and earnings will appear here once you fulfill customer orders.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: RiderTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHistoryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback? onDelete;

  const _DeliveryHistoryCard({
    required this.delivery,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final order = RiderTheme.safeMap(delivery['orderId']);
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final cook = RiderTheme.safeMap(delivery['cookId']);
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";

    final customer = RiderTheme.safeMap(delivery['customerId']);
    final custName = customer?['name'] ?? 'HomeBite Customer';
    final dropLoc = RiderTheme.safeMap(delivery['deliveryLocation']);
    final custAddress =
        dropLoc?['address'] ?? customer?['address'] ?? 'Colombo, Sri Lanka';

    final fee = (delivery['deliveryFee'] as num?)?.toDouble() ?? 450.0;
    final dateStr = delivery['createdAt']?.toString() ?? 'Today';
    final displayDate = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: RiderTheme.secondaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: RiderTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #$orderShort',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            displayDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: RiderTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs. ${fee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RiderTheme.primaryDark,
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remove from history',
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: RiderTheme.textMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: RiderTheme.secondaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DELIVERED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: RiderTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 22),

          // Route: Kitchen -> Customer
          Row(
            children: [
              const Icon(
                Icons.soup_kitchen_rounded,
                size: 16,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cookName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.person_pin_circle_rounded,
                size: 16,
                color: Color(0xFFE53935),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$custName - $custAddress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
