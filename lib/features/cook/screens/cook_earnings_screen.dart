import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../providers/earnings_provider.dart';
import '../theme/cook_theme.dart';

class CookEarningsScreen extends ConsumerStatefulWidget {
  const CookEarningsScreen({super.key});

  @override
  ConsumerState<CookEarningsScreen> createState() => _CookEarningsScreenState();
}

class _CookEarningsScreenState extends ConsumerState<CookEarningsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(earningsProvider.notifier).fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningsProvider);
    final total = state.totalEarnings;
    final today = state.todayEarnings;
    final weekly = state.weeklyEarnings;
    final monthly = state.monthlyEarnings;
    final dailySales = state.dailySales;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Earnings & Revenue',
          style: TextStyle(fontWeight: FontWeight.bold, color: CookTheme.textDark, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        color: CookTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(earningsProvider.notifier).fetchEarnings();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Earnings Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CookTheme.primaryOrange, Color(0xFFFF8A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: CookTheme.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL KITCHEN BALANCE (LKR)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.currency}${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '+18.4% from last week',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Period Statistics Grid (Today, Weekly, Monthly)
              Row(
                children: [
                  Expanded(
                    child: _PeriodCard(
                      label: "Today's Sales",
                      amount: today,
                      icon: Icons.today_rounded,
                      color: CookTheme.primaryDark,
                      bgColor: CookTheme.secondaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PeriodCard(
                      label: 'Weekly',
                      amount: weekly,
                      icon: Icons.calendar_view_week_rounded,
                      color: const Color(0xFF1976D2),
                      bgColor: const Color(0xFFE3F2FD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PeriodCard(
                      label: 'Monthly',
                      amount: monthly,
                      icon: Icons.calendar_month_rounded,
                      color: CookTheme.statusGreen,
                      bgColor: CookTheme.statusGreenBg,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Daily Sales Graph Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Sales Performance',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CookTheme.secondaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Last 7 Days',
                            style: TextStyle(color: CookTheme.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Custom Bar Chart Widget
                    _DailySalesBarChart(data: dailySales),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order Volume Graph Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Volume Count',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 20),
                    _OrderVolumeChart(data: dailySales),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Payout / Earnings History
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CookTheme.textDark),
              ),
              const SizedBox(height: 12),

              if (state.recentEarnings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No transaction records yet.', style: TextStyle(color: CookTheme.textMuted)),
                  ),
                )
              else
                ...state.recentEarnings.map((earning) {
                  final amount = (earning['amount'] as num?)?.toDouble() ?? 0.0;
                  final dateStr = earning['date'] as String?;
                  final formattedDate = dateStr != null && dateStr.length >= 10
                      ? dateStr.substring(0, 10)
                      : 'Today';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: CookTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CookTheme.statusGreenBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, color: CookTheme.statusGreen, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order Fulfillment Payment',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(formattedDate, style: const TextStyle(color: CookTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '+${AppConstants.currency}${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CookTheme.statusGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _PeriodCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CookTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            '${AppConstants.currency}${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: CookTheme.textDark),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: CookTheme.textMuted)),
        ],
      ),
    );
  }
}

class _DailySalesBarChart extends StatelessWidget {
  final List<dynamic> data;

  const _DailySalesBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('No chart data available')),
      );
    }

    double maxSales = 1.0;
    for (final item in data) {
      final s = (item['sales'] as num?)?.toDouble() ?? 0.0;
      if (s > maxSales) maxSales = s;
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((item) {
          final day = (item['day'] as String?) ?? '';
          final sales = (item['sales'] as num?)?.toDouble() ?? 0.0;
          final heightFactor = math.max(0.1, sales / maxSales);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${AppConstants.currency}${sales.toInt()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CookTheme.primaryDark),
              ),
              const SizedBox(height: 6),
              Container(
                width: 24,
                height: 110 * heightFactor,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CookTheme.primaryOrange, Color(0xFFFFB74D)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CookTheme.textMuted),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _OrderVolumeChart extends StatelessWidget {
  final List<dynamic> data;

  const _OrderVolumeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    int maxCount = 1;
    for (final item in data) {
      final c = (item['orderCount'] as num?)?.toInt() ?? 0;
      if (c > maxCount) maxCount = c;
    }

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((item) {
          final day = (item['day'] as String?) ?? '';
          final count = (item['orderCount'] as num?)?.toInt() ?? 0;
          final heightFactor = math.max(0.12, count / maxCount);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
              ),
              const SizedBox(height: 6),
              Container(
                width: 18,
                height: 80 * heightFactor,
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CookTheme.textMuted),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
