import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/report_provider.dart';
import '../theme/admin_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);
    final data = state.data ?? {};

    final sales = data['salesReport'] as Map? ?? {};
    final orders = data['orderReport'] as Map? ?? {};
    final users = data['userReport'] as Map? ?? {};
    final cookPerformance = (data['cookPerformance'] as List?) ?? [];
    final riderPerformance = (data['riderPerformance'] as List?) ?? [];

    final totalSales = sales['totalSales'] ?? 0;
    final totalOrders = sales['totalOrders'] ?? 0;
    final aov = sales['averageOrderValue'] ?? 0;

    final completedOrders = orders['completedOrders'] ?? 0;
    final pendingOrders = orders['pendingOrders'] ?? 0;

    final customerCount = users['customers'] ?? 0;
    final cookCount = users['cooks'] ?? 0;
    final riderCount = users['riders'] ?? 0;

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
          'Platform Reports & Analytics',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(reportProvider.notifier).fetchReports(),
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
                  // Sales Report Section
                  _sectionTitle('Sales Performance Report'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AdminTheme.cardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _kpiItem('Total Sales', 'LKR $totalSales', AdminTheme.primary),
                            _kpiItem('Total Orders', '$totalOrders', const Color(0xFF1976D2)),
                            _kpiItem('Avg Order Value', 'LKR $aov', const Color(0xFF00897B)),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Weekly Revenue Progression (Line Chart)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _LineChartPainter(
                              dataPoints: [20, 45, 35, 60, 52, 75, 90],
                              color: AdminTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order & Fulfillment Report (Bar Chart)
                  _sectionTitle('Order Status Breakdown (Bar Chart)'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AdminTheme.cardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _badgeStat('Completed', '$completedOrders', AdminTheme.statusApproved),
                            _badgeStat('In Fulfillment', '$pendingOrders', AdminTheme.statusPending),
                            _badgeStat('Total Recorded', '$totalOrders', AdminTheme.textPrimary),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BarChartPainter(
                              values: [
                                (completedOrders as num).toDouble(),
                                (pendingOrders as num).toDouble(),
                                2.0,
                              ],
                              labels: const ['Delivered', 'In Transit', 'Cancelled'],
                              colors: const [AdminTheme.statusApproved, AdminTheme.statusPending, AdminTheme.statusRejected],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Distribution (Pie Chart)
                  _sectionTitle('User Community Distribution (Pie Chart)'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AdminTheme.cardDecoration(),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: _PieChartPainter(
                              customers: (customerCount as num).toDouble(),
                              cooks: (cookCount as num).toDouble(),
                              riders: (riderCount as num).toDouble(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _legendRow('Customers', '$customerCount', const Color(0xFF00897B)),
                              const SizedBox(height: 8),
                              _legendRow('Home Cooks', '$cookCount', AdminTheme.primary),
                              const SizedBox(height: 8),
                              _legendRow('Delivery Riders', '$riderCount', const Color(0xFF5E35B1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cook Performance
                  _sectionTitle('Top Home Cooks Performance'),
                  const SizedBox(height: 12),
                  if (cookPerformance.isEmpty)
                    const Text('No cook performance data available.', style: TextStyle(color: AdminTheme.textSecondary))
                  else
                    ...cookPerformance.map((c) {
                      final cMap = c as Map? ?? {};
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: AdminTheme.cardDecoration(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AdminTheme.primaryLight,
                              child: const Icon(Icons.restaurant, color: AdminTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cMap['kitchenName'] ?? 'Kitchen',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.textPrimary),
                                  ),
                                  Text(
                                    '${cMap['totalOrders'] ?? 0} orders • LKR ${cMap['revenue'] ?? 0}',
                                    style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '${cMap['rating'] ?? 4.8}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Rider Performance
                  _sectionTitle('Top Delivery Riders Performance'),
                  const SizedBox(height: 12),
                  if (riderPerformance.isEmpty)
                    const Text('No rider performance data available.', style: TextStyle(color: AdminTheme.textSecondary))
                  else
                    ...riderPerformance.map((r) {
                      final rMap = r as Map? ?? {};
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: AdminTheme.cardDecoration(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFEDE7F6),
                              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF5E35B1), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rMap['name'] ?? 'Rider',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.textPrimary),
                                  ),
                                  Text(
                                    '${rMap['deliveriesCompleted'] ?? 0} deliveries completed',
                                    style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '${rMap['rating'] ?? 4.9}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
    );
  }

  Widget _kpiItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _badgeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
      ],
    );
  }

  Widget _legendRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Custom Painters for Pixel-Perfect Charts
class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  _LineChartPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxVal = dataPoints.reduce(max);
    final minVal = dataPoints.reduce(min);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - ((dataPoints[i] - minVal) / range * (size.height - 20) + 10);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dot
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;

  _BarChartPainter({required this.values, required this.labels, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = max(1.0, values.reduce(max));
    final barWidth = size.width / (values.length * 2);

    for (int i = 0; i < values.length; i++) {
      final left = (i * 2 + 0.5) * barWidth;
      final barHeight = (values[i] / maxVal) * (size.height - 30);
      final top = size.height - barHeight - 20;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, paint);

      // Label text
      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left + (barWidth - textPainter.width) / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  final double customers;
  final double cooks;
  final double riders;

  _PieChartPainter({required this.customers, required this.cooks, required this.riders});

  @override
  void paint(Canvas canvas, Size size) {
    final total = max(1.0, customers + cooks + riders);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    double startAngle = -pi / 2;

    final data = [
      {'val': customers, 'color': const Color(0xFF00897B)},
      {'val': cooks, 'color': AdminTheme.primary},
      {'val': riders, 'color': const Color(0xFF5E35B1)},
    ];

    for (final item in data) {
      final sweepAngle = ((item['val'] as double) / total) * 2 * pi;
      final paint = Paint()
        ..color = item['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Inner circle for donut appearance
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.3, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
