import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/order_management_provider.dart';
import '../theme/admin_theme.dart';

class OrderMonitoringScreen extends ConsumerStatefulWidget {
  const OrderMonitoringScreen({super.key});

  @override
  ConsumerState<OrderMonitoringScreen> createState() => _OrderMonitoringScreenState();
}

class _OrderMonitoringScreenState extends ConsumerState<OrderMonitoringScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = ['All Orders', 'Active', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    Future.microtask(() => ref.read(orderManagementProvider.notifier).loadOrders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> allOrders) {
    return allOrders.where((o) {
      final status = (o['status'] as String? ?? '').toLowerCase();
      final tab = _tabs[_tabController.index].toLowerCase();

      bool matchesTab = true;
      if (tab == 'active') {
        matchesTab = !status.contains('delivered') && !status.contains('cancelled');
      } else if (tab == 'delivered') {
        matchesTab = status.contains('delivered');
      }

      final id = (o['_id'] as String? ?? '').toLowerCase();
      final customer = o['customer'] as Map? ?? {};
      final customerName = (customer['name'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesQuery = q.isEmpty || id.contains(q) || customerName.contains(q);

      return matchesTab && matchesQuery;
    }).toList();
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final id = order['_id'] as String? ?? '';
    final shortId = id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
    final customer = order['customer'] as Map? ?? {};
    final cook = order['cook'] as Map? ?? {};
    final rider = order['rider'] as Map? ?? {};
    final items = (order['items'] as List?) ?? [];
    final total = order['total'] ?? 0;
    final status = order['status'] ?? 'Order Received';
    final address = order['deliveryAddress'] ?? 'Colombo 07, Sri Lanka';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #$shortId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _sectionHeader('Customer & Delivery'),
              _infoRow('Customer Name', customer['name'] ?? 'HomeBite Customer'),
              _infoRow('Phone', customer['phone'] ?? '+94 71 890 1234'),
              _infoRow('Address', address),
              const SizedBox(height: 14),
              _sectionHeader('Supplier & Fulfillment'),
              _infoRow('Kitchen', cook['kitchenName'] ?? cook['name'] ?? 'Home Kitchen'),
              _infoRow('Chef Name', cook['name'] ?? 'Chef'),
              _infoRow('Assigned Rider', rider.isNotEmpty ? '${rider['name']} (${rider['phone'] ?? ''})' : 'Pending rider assignment'),
              const SizedBox(height: 14),
              _sectionHeader('Order Items'),
              const SizedBox(height: 6),
              ...items.map((it) {
                final itMap = it as Map? ?? {};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${itMap['quantity'] ?? 1}x ${itMap['name'] ?? 'Dish'}',
                        style: const TextStyle(fontSize: 13, color: AdminTheme.textPrimary),
                      ),
                      Text(
                        'LKR ${itMap['price'] ?? 0}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    'LKR $total',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderManagementProvider);
    final filteredOrders = _filterOrders(state.orders);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Monitoring',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(orderManagementProvider.notifier).loadOrders(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AdminTheme.primary,
          indicatorWeight: 3,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: AdminTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Order ID or customer...',
                prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AdminTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AdminTheme.primary,
              onRefresh: () => ref.read(orderManagementProvider.notifier).loadOrders(),
              child: state.isLoading && state.orders.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) => const OrderCardSkeleton(),
                    )
                  : filteredOrders.isEmpty
                      ? const Center(
                          child: Text('No orders found in this view', style: TextStyle(color: AdminTheme.textSecondary)),
                        )
                      : ListView.separated(
                          key: const PageStorageKey<String>('admin_orders_scroll'),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final o = filteredOrders[index];
                          final id = o['_id'] as String? ?? '';
                          final shortId = id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
                          final customer = o['customer'] as Map? ?? {};
                          final cook = o['cook'] as Map? ?? {};
                          final total = o['total'] ?? 0;
                          final status = o['status'] as String? ?? 'Order Received';

                          Color statusColor = AdminTheme.statusPending;
                          Color statusBg = AdminTheme.statusPendingBg;

                          if (status.toLowerCase().contains('delivered')) {
                            statusColor = AdminTheme.statusApproved;
                            statusBg = AdminTheme.statusApprovedBg;
                          } else if (status.toLowerCase().contains('transit') || status.toLowerCase().contains('pickup')) {
                            statusColor = const Color(0xFF1976D2);
                            statusBg = const Color(0xFFE3F2FD);
                          }

                          return InkWell(
                            onTap: () => _showOrderDetails(o),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AdminTheme.cardDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#ORD-$shortId',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminTheme.textPrimary),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          status,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 16, color: AdminTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Customer: ${customer['name'] ?? 'HomeBite User'}',
                                        style: const TextStyle(fontSize: 13, color: AdminTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.restaurant_outlined, size: 16, color: AdminTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cook: ${cook['kitchenName'] ?? cook['name'] ?? 'Home Kitchen'}',
                                        style: const TextStyle(fontSize: 13, color: AdminTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Order Total:', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                                      Text(
                                        'LKR $total',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
