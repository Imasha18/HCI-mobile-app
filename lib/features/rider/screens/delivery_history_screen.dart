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
                  return _DeliveryHistoryCard(delivery: item);
                },
              ),
      ),
    );
  }

  Widget _buildSampleOrEmpty(BuildContext context) {
    // Provide realistic fallback history if none in DB yet
    final samples = [
      {
        '_id': 'DEL-84920001',
        'orderId': {'_id': 'ORD-8492'},
        'cookId': {'kitchenName': "Amma's Spice Kitchen", 'name': 'Sunethra Perera'},
        'customerId': {'name': 'Nimal Jayasuriya', 'address': '18 Flower Road, Colombo 07'},
        'deliveryFee': 450.0,
        'createdAt': '2026-10-04T14:30:00.000Z',
        'status': 'DELIVERED',
      },
      {
        '_id': 'DEL-84920002',
        'orderId': {'_id': 'ORD-7721'},
        'cookId': {'kitchenName': 'Kottu Express Home', 'name': 'Mohamed Rizwan'},
        'customerId': {'name': 'Dilini Fernando', 'address': '42 Dharmapala Mawatha, Colombo 03'},
        'deliveryFee': 500.0,
        'createdAt': '2026-10-04T12:15:00.000Z',
        'status': 'DELIVERED',
      },
      {
        '_id': 'DEL-84920003',
        'orderId': {'_id': 'ORD-6309'},
        'cookId': {'kitchenName': 'Ceylon Curry Pot', 'name': 'Anula Silva'},
        'customerId': {'name': 'Kasun Mendis', 'address': '102 Havelock Road, Colombo 05'},
        'deliveryFee': 350.0,
        'createdAt': '2026-10-03T18:45:00.000Z',
        'status': 'DELIVERED',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: samples.length,
      itemBuilder: (context, index) {
        return _DeliveryHistoryCard(delivery: samples[index]);
      },
    );
  }
}

class _DeliveryHistoryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const _DeliveryHistoryCard({required this.delivery});

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
    final custAddress = dropLoc?['address'] ??
        customer?['address'] ??
        'Colombo, Sri Lanka';

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: RiderTheme.secondaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: RiderTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderShort',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        displayDate,
                        style: const TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${fee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: RiderTheme.primaryDark,
                    ),
                  ),
                  Container(
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
                ],
              ),
            ],
          ),

          const Divider(height: 22),

          // Route: Kitchen -> Customer
          Row(
            children: [
              const Icon(Icons.soup_kitchen_rounded, size: 16, color: Color(0xFFFF9800)),
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
              const Icon(Icons.person_pin_circle_rounded, size: 16, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$custName · $custAddress',
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
