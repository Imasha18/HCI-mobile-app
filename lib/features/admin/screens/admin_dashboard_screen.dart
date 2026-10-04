import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';
import 'admin_profile_screen.dart';
import 'order_monitoring_screen.dart';
import 'reports_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchDashboard());
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final data = adminState.dashboardData ?? {};
    final user = adminState.adminUser ?? {};

    final totalUsers = data['totalUsers'] ?? 0;
    final totalCustomers = data['totalCustomers'] ?? 0;
    final totalCooks = data['totalCooks'] ?? 0;
    final totalRiders = data['totalRiders'] ?? 0;
    final totalOrders = data['totalOrders'] ?? 0;
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
    final pendingVerifications = data['pendingVerifications'] ?? 0;
    final openComplaints = data['openComplaints'] ?? 0;
    final recentActivities = (data['recentActivities'] as List?) ?? [];

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _currentNavIndex == 0
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AdminTheme.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AdminTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AdminTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Admin Panel',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        const Text(
                          'Super Administrator',
                          style: TextStyle(
                            fontSize: 11,
                            color: AdminTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, color: AdminTheme.textPrimary, size: 24),
                        if (pendingVerifications > 0 || openComplaints > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AdminTheme.statusRejected,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${pendingVerifications + openComplaints}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.adminNotifications),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AdminTheme.textSecondary, size: 22),
                    onPressed: () async {
                      await ref.read(adminProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : null,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            RefreshIndicator(
              color: AdminTheme.primary,
              onRefresh: () => ref.read(adminProvider.notifier).fetchDashboard(forceRefresh: true),
              child: SingleChildScrollView(
                key: const PageStorageKey<String>('admin_dashboard_scroll'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Welcome back, Admin 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'Live System',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Overview of HomeBite platform operations, live statistics, and system alerts.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Section Header
              const Text(
                'Key Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 6 Statistics Cards in Grid (2 columns)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.45,
                children: [
                  _StatCard(
                    title: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF1976D2),
                    iconBg: const Color(0xFFE3F2FD),
                  ),
                  _StatCard(
                    title: 'Total Customers',
                    value: '$totalCustomers',
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF00897B),
                    iconBg: const Color(0xFFE0F2F1),
                  ),
                  _StatCard(
                    title: 'Total Cooks',
                    value: '$totalCooks',
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: const Color(0xFFE65100),
                    iconBg: const Color(0xFFFFE0B2),
                  ),
                  _StatCard(
                    title: 'Total Riders',
                    value: '$totalRiders',
                    icon: Icons.two_wheeler_rounded,
                    iconColor: const Color(0xFF5E35B1),
                    iconBg: const Color(0xFFEDE7F6),
                  ),
                  _StatCard(
                    title: 'Total Orders',
                    value: '$totalOrders',
                    icon: Icons.shopping_bag_rounded,
                    iconColor: const Color(0xFFD81B60),
                    iconBg: const Color(0xFFFCE4EC),
                  ),
                  _StatCard(
                    title: 'Revenue',
                    value: 'LKR ${revenue.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    iconBg: const Color(0xFFE8F5E9),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick Actions Header
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Quick Actions List
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Verify Users',
                      subtitle: '$pendingVerifications pending',
                      icon: Icons.verified_user_rounded,
                      color: AdminTheme.primary,
                      badgeCount: pendingVerifications,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminVerification),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Manage Orders',
                      subtitle: '$totalOrders recorded',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF1976D2),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminOrders),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'View Reports',
                      subtitle: 'Analytics & Sales',
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF7B1FA2),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminReports),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Meal Moderation',
                      subtitle: 'Monitor menu',
                      icon: Icons.lunch_dining_rounded,
                      color: const Color(0xFF00897B),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminMeals),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'User Complaints',
                      subtitle: '$openComplaints active',
                      icon: Icons.report_problem_rounded,
                      color: const Color(0xFFE53935),
                      badgeCount: openComplaints,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminComplaints),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Live Statistics',
                      subtitle: 'Daily trends',
                      icon: Icons.insights_rounded,
                      color: const Color(0xFFF57C00),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminStatistics),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Activities Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.adminNotifications),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AdminTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent Activities Feed
              if (recentActivities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AdminTheme.cardDecoration(),
                  child: const Center(
                    child: Text(
                      'No recent platform activities yet.',
                      style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < (recentActivities.length > 5 ? 5 : recentActivities.length); i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final item = recentActivities[i] as Map<String, dynamic>;
                          final type = item['type'] as String? ?? 'general';
                          final title = item['title'] as String? ?? 'Activity';
                          final subtitle = item['subtitle'] as String? ?? '';
                          final status = item['status'] as String? ?? '';

                          IconData icon;
                          Color iconColor;
                          Color iconBg;

                          if (type.contains('cook')) {
                            icon = Icons.restaurant_rounded;
                            iconColor = AdminTheme.primary;
                            iconBg = AdminTheme.primaryLight;
                          } else if (type.contains('rider')) {
                            icon = Icons.two_wheeler_rounded;
                            iconColor = const Color(0xFF5E35B1);
                            iconBg = const Color(0xFFEDE7F6);
                          } else if (type.contains('order')) {
                            icon = Icons.receipt_rounded;
                            iconColor = const Color(0xFF1976D2);
                            iconBg = const Color(0xFFE3F2FD);
                          } else if (type.contains('complaint')) {
                            icon = Icons.warning_amber_rounded;
                            iconColor = AdminTheme.statusRejected;
                            iconBg = AdminTheme.statusRejectedBg;
                          } else {
                            icon = Icons.person_add_rounded;
                            iconColor = const Color(0xFF00897B);
                            iconBg = const Color(0xFFE0F2F1);
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: AdminTheme.cardDecoration(),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AdminTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AdminTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (status.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status.toLowerCase() == 'pending'
                                          ? AdminTheme.statusPendingBg
                                          : status.toLowerCase() == 'delivered' || status.toLowerCase() == 'verified'
                                              ? AdminTheme.statusApprovedBg
                                              : AdminTheme.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: status.toLowerCase() == 'pending'
                                            ? AdminTheme.statusPending
                                            : status.toLowerCase() == 'delivered' || status.toLowerCase() == 'verified'
                                                ? AdminTheme.statusApproved
                                                : AdminTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      const UserManagementScreen(),
      const OrderMonitoringScreen(),
      const ReportsScreen(),
      const AdminProfileScreen(),
    ],
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentNavIndex,
    onTap: _onBottomNavTapped,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    selectedItemColor: AdminTheme.primary,
    unselectedItemColor: AdminTheme.textMuted,
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
    unselectedLabelStyle: const TextStyle(fontSize: 11),
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.group_rounded),
        label: 'Users',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_rounded),
        label: 'Orders',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.analytics_rounded),
        label: 'Reports',
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
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AdminTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
              letterSpacing: -0.5,
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
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _QuickActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: AdminTheme.cardDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AdminTheme.statusRejected,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AdminTheme.textSecondary,
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
