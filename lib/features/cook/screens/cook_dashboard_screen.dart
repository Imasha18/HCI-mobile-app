import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../providers/cook_provider.dart';
import '../theme/cook_theme.dart';

class CookDashboardScreen extends ConsumerStatefulWidget {
  const CookDashboardScreen({super.key});

  @override
  ConsumerState<CookDashboardScreen> createState() => _CookDashboardScreenState();
}

class _CookDashboardScreenState extends ConsumerState<CookDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cookProvider.notifier).fetchDashboard();
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        // Already home
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.cookOrders);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.manageMenu);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.cookEarnings);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.cookProfileSettings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookProvider);
    final dashboard = state.dashboardData;
    final cookInfo = dashboard?['cook'] as Map<String, dynamic>?;
    final stats = dashboard?['statistics'] as Map<String, dynamic>?;
    final recentOrders = (dashboard?['recentOrders'] as List<dynamic>?) ?? [];

    final cookName = cookInfo?['name'] as String? ?? state.cook?['name'] ?? 'Chef Sarah';
    final kitchenName = cookInfo?['kitchenName'] as String? ?? "Sarah's Gourmet Kitchen";
    final profileImage = cookInfo?['profileImage'] as String? ?? '';
    final rating = (cookInfo?['rating'] as num?)?.toDouble() ?? 4.9;
    final isOnline = state.isOnline;

    final todayOrdersCount = stats?['todayOrders'] ?? 8;
    final totalRevenue = (stats?['totalRevenue'] as num?)?.toDouble() ?? 324.50;
    final avgRating = (stats?['averageRating'] as num?)?.toDouble() ?? rating;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            // Cook Profile Avatar with Border
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CookTheme.primaryOrange, width: 2),
                image: profileImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(profileImage),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: CookTheme.secondaryOrange,
              ),
              child: profileImage.isEmpty
                  ? const Icon(Icons.person, color: CookTheme.primaryOrange, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cookName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CookTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    kitchenName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CookTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Online / Offline Switch Badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? CookTheme.statusGreenBg : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? CookTheme.statusGreen : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? CookTheme.statusGreen : Colors.grey.shade600,
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: (val) {
                    ref.read(cookProvider.notifier).toggleOnlineStatus(val);
                  },
                  activeThumbColor: CookTheme.statusGreen,
                  activeTrackColor: CookTheme.statusGreenBg,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          // Notifications icon
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: CookTheme.textDark),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cookNotifications),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: CookTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(cookProvider.notifier).fetchDashboard();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CookTheme.primaryOrange, Color(0xFFFF8A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: CookTheme.elevatedShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back, Chef!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isOnline
                              ? 'Your kitchen is open and accepting new orders.'
                              : 'Kitchen is currently paused. Switch online to get orders.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.skateboarding_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Header
            const Text(
              'Kitchen Overview',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: CookTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Statistics Cards Row (Today's Orders, Revenue, Rating)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Today's Orders",
                    value: '$todayOrdersCount',
                    icon: Icons.receipt_long_rounded,
                    iconBgColor: CookTheme.secondaryOrange,
                    iconColor: CookTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Revenue',
                    value: '${AppConstants.currency}${totalRevenue.toStringAsFixed(2)}',
                    icon: Icons.payments_rounded,
                    iconBgColor: CookTheme.statusGreenBg,
                    iconColor: CookTheme.statusGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Avg Rating',
                    value: avgRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    iconBgColor: const Color(0xFFFFF9C4),
                    iconColor: const Color(0xFFF57F17),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: CookTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.receipt_outlined,
                    label: 'View Orders',
                    color: CookTheme.primaryOrange,
                    bgColor: CookTheme.secondaryOrange,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.cookOrders),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.menu_book_rounded,
                    label: 'Manage Menu',
                    color: const Color(0xFF1976D2),
                    bgColor: const Color(0xFFE3F2FD),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.manageMenu),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add Meal',
                    color: const Color(0xFF388E3C),
                    bgColor: const Color(0xFFE8F5E9),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.addMeal),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Recent Orders Header with View All
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: CookTheme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.cookOrders),
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: CookTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Orders List
            if (recentOrders.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No recent orders yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CookTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'When customers place orders, they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: CookTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...recentOrders.map((order) {
                final customer = order['customer'] as Map<String, dynamic>?;
                final customerName = customer?['name'] as String? ?? 'Customer';
                final items = (order['items'] as List<dynamic>?) ?? [];
                final firstItem = items.isNotEmpty ? items[0] as Map<String, dynamic>? : null;
                final mealName = firstItem?['name'] as String? ??
                    (firstItem?['meal'] as Map<String, dynamic>?)?['name'] as String? ??
                    'Special Meal';
                final quantity = firstItem?['quantity'] as int? ?? 1;
                final price = (order['total'] as num?)?.toDouble() ?? 0.0;
                final status = (order['status'] as String?) ?? 'Order Received';
                final orderId = order['_id'] as String? ?? '';

                return _RecentOrderCard(
                  customerName: customerName,
                  mealName: items.length > 1 ? '$mealName + ${items.length - 1} more' : mealName,
                  quantity: quantity,
                  price: price,
                  status: status,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.cookOrderDetails,
                      arguments: orderId,
                    );
                  },
                );
              }),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: CookTheme.primaryOrange,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: CookTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: CookTheme.textDark,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: CookTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: CookTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CookTheme.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final String customerName;
  final String mealName;
  final int quantity;
  final double price;
  final String status;
  final VoidCallback onTap;

  const _RecentOrderCard({
    required this.customerName,
    required this.mealName,
    required this.quantity,
    required this.price,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = CookTheme.getStatusColor(status);
    final statusBgColor = CookTheme.getStatusBgColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: CookTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Food avatar icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CookTheme.secondaryOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fastfood_rounded,
                    color: CookTheme.primaryOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Order information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: CookTheme.textDark,
                            ),
                          ),
                          Text(
                            '${AppConstants.currency}${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: CookTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantity × $mealName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CookTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
