import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_provider.dart';
import '../theme/admin_theme.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsProvider);
    final data = state.data ?? {};

    final dailyOrders = data['dailyOrders'] ?? 0;
    final monthlyRevenue = (data['monthlyRevenue'] as num?)?.toDouble() ?? 0.0;
    final activeUsers = data['activeUsers'] ?? 0;
    final popularMeals = (data['popularMeals'] as List?) ?? [];
    final revenueGraph = (data['revenueGraph'] as List?) ?? [];
    final orderGraph = (data['orderGraph'] as List?) ?? [];

    final revenuePoints = revenueGraph.map((e) => ((e['amount'] as num?) ?? 1000).toDouble()).toList();
    final revenueLabels = revenueGraph.map((e) => (e['day'] as String?) ?? '').toList();

    final orderPoints = orderGraph.map((e) => ((e['orders'] as num?) ?? 5).toDouble()).toList();
    final orderLabels = orderGraph.map((e) => (e['day'] as String?) ?? '').toList();

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
          'Live Statistics & Trends',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(statisticsProvider.notifier).fetchStatistics(),
          ),
        ],
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3 Key Metrics
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          title: 'Daily Orders',
                          value: '$dailyOrders',
                          icon: Icons.today_rounded,
                          color: const Color(0xFF1976D2),
                          bg: const Color(0xFFE3F2FD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          title: 'Active Users',
                          value: '$activeUsers online',
                          icon: Icons.wifi_tethering_rounded,
                          color: const Color(0xFF00897B),
                          bg: const Color(0xFFE0F2F1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: AdminTheme.cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Revenue', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${monthlyRevenue.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AdminTheme.primary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.trending_up_rounded, color: AdminTheme.primary, size: 28),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Revenue Graph (Weekly)
                  _sectionHeader('Weekly Revenue Trend (LKR)'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AdminTheme.cardDecoration(),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _TrendGraphPainter(
                              dataPoints: revenuePoints.isNotEmpty ? revenuePoints : [1200, 3400, 2800, 5100, 4200, 6800, 7500],
                              labels: revenueLabels.isNotEmpty ? revenueLabels : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                              lineColor: AdminTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order Volume Graph
                  _sectionHeader('Daily Order Volume Trend'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AdminTheme.cardDecoration(),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _TrendGraphPainter(
                              dataPoints: orderPoints.isNotEmpty ? orderPoints : [5, 12, 8, 15, 14, 22, 19],
                              labels: orderLabels.isNotEmpty ? orderLabels : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                              lineColor: const Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Popular Meals
                  _sectionHeader('Most Popular Meals'),
                  const SizedBox(height: 12),
                  if (popularMeals.isEmpty)
                    const Text('No meals data available', style: TextStyle(color: AdminTheme.textSecondary))
                  else
                    ...popularMeals.map((m) {
                      final mMap = m as Map? ?? {};
                      final cook = mMap['cook'] as Map? ?? {};
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: AdminTheme.cardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.lunch_dining_rounded, color: AdminTheme.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mMap['name'] ?? 'Dish',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.textPrimary),
                                  ),
                                  Text(
                                    'Kitchen: ${cook['kitchenName'] ?? cook['name'] ?? 'Home Cook'}',
                                    style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'LKR ${mMap['price'] ?? 0}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.primary),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${mMap['rating'] ?? 5.0}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TrendGraphPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final Color lineColor;

  _TrendGraphPainter({
    required this.dataPoints,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final maxVal = max(1.0, dataPoints.reduce(max));
    final minVal = dataPoints.reduce(min);
    final range = max(1.0, maxVal - minVal);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height - 25))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = (size.height - 30) - ((dataPoints[i] - minVal) / range * (size.height - 50) + 10);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - 25);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dot
      final dotPaint = Paint()..color = lineColor;
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);

      // Label below
      if (i < labels.length) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - 18));
      }
    }

    fillPath.lineTo(size.width, size.height - 25);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
