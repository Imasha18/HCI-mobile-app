import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/rider_provider.dart';
import '../theme/rider_theme.dart';
import 'delivery_requests_screen.dart';
import 'rider_earnings_screen.dart';
import 'rider_profile_screen.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderProvider.notifier).fetchDashboard();
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderProvider);
    final dashboard = state.dashboardData;
    final riderInfo = (dashboard?['rider'] as Map<String, dynamic>?) ?? state.rider;
    final statistics = dashboard?['statistics'] as Map<String, dynamic>?;
    final currentDelivery = dashboard?['currentDelivery'] as Map<String, dynamic>?;

    final riderName = riderInfo?['name'] as String? ?? state.rider?['name'] as String? ?? 'Delivery Rider';
    final profileImage = riderInfo?['profileImage'] as String? ?? state.rider?['profileImage'] as String?;
    final vehicle = (riderInfo?['vehicleDetails'] as Map<String, dynamic>?) ?? (state.rider?['vehicleDetails'] as Map<String, dynamic>?);
    final vehicleModel = vehicle?['model'] ?? vehicle?['type'] ?? 'Motorbike';
    final plateNumber = vehicle?['plateNumber'] as String? ?? '';
    final vehicleStr = plateNumber.isNotEmpty ? '$vehicleModel · $plateNumber' : vehicleModel;

    final todayDeliveries = ((statistics?['todayDeliveries'] as num?)?.toInt() ?? 0).toString();
    final todayEarningsNum = (statistics?['todayEarnings'] as num?)?.toDouble() ?? 0.0;
    final rating = (statistics?['rating'] ?? riderInfo?['rating'] ?? state.rider?['rating'] ?? 5.0).toString();
    final distanceTravelled = '${((statistics?['distanceTravelled'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} km';

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBF9),
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            SafeArea(
              child: RefreshIndicator(
                color: RiderTheme.primaryGreen,
                onRefresh: () => ref.read(riderProvider.notifier).fetchDashboard(forceRefresh: true),
                child: SingleChildScrollView(
                  key: const PageStorageKey<String>('rider_dashboard_scroll'),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Green Header Section
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        decoration: const BoxDecoration(
                          color: RiderTheme.primaryGreen,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Top Row: Profile info & Notifications
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white,
                                  backgroundImage: profileImage != null && profileImage.isNotEmpty
                                      ? CachedNetworkImageProvider(profileImage)
                                      : null,
                            child: profileImage == null || profileImage.isEmpty
                                ? const Icon(Icons.person, color: RiderTheme.primaryGreen, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      riderName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vehicleStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.riderNotifications),
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Online / Offline Status Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: RiderTheme.softShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: state.isOnline ? RiderTheme.primaryGreen : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  state.isOnline ? 'Online & Ready for Deliveries' : 'Offline (Not receiving orders)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: state.isOnline ? RiderTheme.primaryDark : RiderTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: state.isOnline,
                              activeTrackColor: RiderTheme.primaryGreen,
                              onChanged: (val) {
                                ref.read(riderProvider.notifier).toggleOnlineStatus(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Statistics Grid Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RiderTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: "Today's Deliveries",
                              value: todayDeliveries,
                              icon: Icons.delivery_dining_rounded,
                              iconColor: RiderTheme.primaryGreen,
                              bgColor: RiderTheme.secondaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: "Today's Earnings",
                              value: 'Rs. ${todayEarningsNum.toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: const Color(0xFF1565C0),
                              bgColor: const Color(0xFFE3F2FD),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Rider Rating',
                              value: '$rating ★',
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFB300),
                              bgColor: const Color(0xFFFFF8E1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Distance Travelled',
                              value: distanceTravelled,
                              icon: Icons.speed_rounded,
                              iconColor: const Color(0xFF8E24AA),
                              bgColor: const Color(0xFFF3E5F5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Current Active Delivery Card (if assigned)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Delivery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: RiderTheme.textDark,
                            ),
                          ),
                          if (currentDelivery != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: RiderTheme.getStatusBgColor(currentDelivery['status'] ?? 'ACCEPTED'),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (currentDelivery['status'] as String? ?? 'ACCEPTED').replaceAll('_', ' '),
                                style: TextStyle(
                                  color: RiderTheme.getStatusColor(currentDelivery['status'] ?? 'ACCEPTED'),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (currentDelivery != null)
                        _CurrentDeliveryCard(delivery: currentDelivery)
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: RiderTheme.softShadow,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.two_wheeler_outlined, size: 44, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text(
                                'No Active Delivery Right Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: RiderTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Check available delivery requests near you to start earning.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: RiderTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.deliveryRequests),
                                icon: const Icon(Icons.near_me_rounded, size: 18),
                                label: const Text('Find Deliveries'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: RiderTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RiderTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Delivery\nRequests',
                              icon: Icons.list_alt_rounded,
                              color: RiderTheme.primaryGreen,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.deliveryRequests),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionCard(
                              title: 'My\nEarnings',
                              icon: Icons.insights_rounded,
                              color: const Color(0xFF1565C0),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.riderEarnings),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Delivery\nHistory',
                              icon: Icons.history_rounded,
                              color: const Color(0xFFE65100),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.deliveryHistory),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Rider\nProfile',
                              icon: Icons.badge_rounded,
                              color: const Color(0xFF7B1FA2),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.riderProfile),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
      const DeliveryRequestsScreen(),
      const RiderEarningsScreen(),
      const RiderProfileScreen(),
    ],
  ),
  bottomNavigationBar: NavigationBar(
    selectedIndex: _currentNavIndex,
    backgroundColor: Colors.white,
    elevation: 6,
    indicatorColor: RiderTheme.secondaryGreen,
    onDestinationSelected: _onBottomNavTapped,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded, color: RiderTheme.primaryDark),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.delivery_dining_outlined),
        selectedIcon: Icon(Icons.delivery_dining_rounded, color: RiderTheme.primaryDark),
        label: 'Deliveries',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: RiderTheme.primaryDark),
        label: 'Earnings',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded, color: RiderTheme.primaryDark),
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
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: RiderTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RiderTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: RiderTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentDeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const _CurrentDeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final deliveryId = (delivery['_id'] ?? delivery['id'] ?? '').toString();
    final order = delivery['orderId'] as Map<String, dynamic>?;
    final orderId = (order?['_id'] ?? delivery['orderId'] ?? '').toString();
    final orderShort = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    final cook = delivery['cookId'] as Map<String, dynamic>?;
    final cookName = cook?['kitchenName'] ?? cook?['name'] ?? "Amma's Spice Kitchen";
    final pickupAddr = delivery['pickupLocation']?['address'] ?? cook?['address'] ?? '45/2 Galle Road, Colombo 03';

    final customer = delivery['customerId'] as Map<String, dynamic>?;
    final custName = customer?['name'] ?? 'Nimal Jayasuriya';
    final dropAddr = delivery['deliveryLocation']?['address'] ?? customer?['address'] ?? '18 Flower Road, Colombo 07';

    final deliveryFee = (delivery['deliveryFee'] as num?)?.toDouble() ?? 450.0;
    final status = (delivery['status'] as String? ?? 'ACCEPTED').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: RiderTheme.softShadow,
        border: Border.all(color: RiderTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderShort',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Rs. ${deliveryFee.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: RiderTheme.primaryDark,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Pickup Location Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup: $cookName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      pickupAddr,
                      style: const TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Delivery Location Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: RiderTheme.secondaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, size: 16, color: RiderTheme.primaryGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deliver to: $custName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      dropAddr,
                      style: const TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Action Button depending on status
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (status == 'ACCEPTED') {
                  Navigator.pushNamed(context, AppRoutes.riderPickup, arguments: delivery);
                } else if (status == 'PICKED_UP' || status == 'IN_TRANSIT') {
                  Navigator.pushNamed(context, AppRoutes.riderInTransit, arguments: delivery);
                } else {
                  Navigator.pushNamed(context, AppRoutes.deliveryRequestDetails, arguments: deliveryId);
                }
              },
              icon: Icon(
                status == 'ACCEPTED'
                    ? Icons.store_rounded
                    : (status == 'PICKED_UP' ? Icons.navigation_rounded : Icons.check_circle_outline_rounded),
                size: 20,
              ),
              label: Text(
                status == 'ACCEPTED'
                    ? 'Go to Pickup Location'
                    : (status == 'PICKED_UP' ? 'Start Transit to Customer' : 'Confirm Delivery'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: RiderTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: RiderTheme.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
