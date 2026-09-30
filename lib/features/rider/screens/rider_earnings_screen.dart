import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/earnings_provider.dart';
import '../theme/rider_theme.dart';

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  int _selectedChartTab = 0; // 0: Revenue, 1: Deliveries

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsProvider.notifier).fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsProvider);
    final breakdown = earningsState.dailyBreakdown;

    final maxRevenue = breakdown.fold<double>(
      1000.0,
      (max, item) => (item['amount'] as double) > max ? (item['amount'] as double) : max,
    );

    final maxDeliveries = breakdown.fold<int>(
      1,
      (max, item) => (item['deliveries'] as int) > max ? (item['deliveries'] as int) : max,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'My Earnings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Delivery History',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.deliveryHistory),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(earningsProvider.notifier).fetchEarnings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: RiderTheme.primaryGreen,
        onRefresh: () => ref.read(earningsProvider.notifier).fetchEarnings(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Total Earnings Hero Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RiderTheme.primaryGreen, Color(0xFF138A3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: RiderTheme.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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
                        'Total Balance Earned',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Weekly Payout',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs. ${earningsState.totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Next direct deposit scheduled for Monday',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Today / This Week / This Month Cards
            Row(
              children: [
                Expanded(
                  child: _PeriodStatCard(
                    title: 'Today',
                    amount: earningsState.todayEarnings,
                    icon: Icons.today_rounded,
                    color: RiderTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PeriodStatCard(
                    title: 'This Week',
                    amount: earningsState.weeklyEarnings,
                    icon: Icons.date_range_rounded,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PeriodStatCard(
                    title: 'This Month',
                    amount: earningsState.monthlyEarnings,
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF8E24AA),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Performance Charts Section
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Analytics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      // Toggle between Revenue and Deliveries
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _ChartTabButton(
                              label: 'Revenue',
                              isSelected: _selectedChartTab == 0,
                              onTap: () => setState(() => _selectedChartTab = 0),
                            ),
                            _ChartTabButton(
                              label: 'Trips',
                              isSelected: _selectedChartTab == 1,
                              onTap: () => setState(() => _selectedChartTab = 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Chart Display
                  SizedBox(
                    height: 180,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: breakdown.map((item) {
                        final isRevenue = _selectedChartTab == 0;
                        final value = isRevenue
                            ? (item['amount'] as double)
                            : (item['deliveries'] as int).toDouble();
                        final maxValue = isRevenue ? maxRevenue : maxDeliveries.toDouble();
                        final ratio = (maxValue > 0 ? (value / maxValue) : 0.0).clamp(0.08, 1.0);

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              isRevenue ? '${(value / 1000).toStringAsFixed(1)}k' : '${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: RiderTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 28,
                              height: 120 * ratio,
                              decoration: BoxDecoration(
                                color: item['day'] == 'Sat'
                                    ? RiderTheme.primaryGreen
                                    : RiderTheme.secondaryGreen,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: item['day'] == 'Sat'
                                      ? RiderTheme.primaryDark
                                      : RiderTheme.primaryGreen.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['day'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: item['day'] == 'Sat' ? FontWeight.bold : FontWeight.w500,
                                color: item['day'] == 'Sat' ? RiderTheme.primaryDark : RiderTheme.textDark,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Link to Delivery History
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: RiderTheme.secondaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu_rounded, color: RiderTheme.primaryGreen),
              ),
              title: const Text('Detailed Delivery History', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('View receipt breakdown and customer drops', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: RiderTheme.textMuted),
              onTap: () => Navigator.pushNamed(context, AppRoutes.deliveryHistory),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _PeriodStatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: RiderTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: RiderTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: RiderTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChartTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RiderTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : RiderTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
