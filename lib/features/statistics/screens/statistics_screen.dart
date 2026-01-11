import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/widgets/page_header.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  // Predefined list of colors for pie chart sections
  static const List<Color> _chartColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.yellow, Colors.cyan, Colors.pink, Colors.teal, Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Statistics',
                subtitle: '생산성 패턴을 확인해보세요.',
                color: colorScheme.tertiary,
              ),
              const SizedBox(height: 32),
              _buildFocusSummary(context),
              const SizedBox(height: 24),
              _buildWeeklyChart(context),
              const SizedBox(height: 24),
              _buildContextBreakdown(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusSummary(BuildContext context) {
    final stats = context.select((ActionProvider p) => p.weeklyFocusStats);
    final Duration totalTime = stats['totalTime'] as Duration;
    final int totalPomodoros = stats['totalPomodoros'] as int;
    final colorScheme = Theme.of(context).colorScheme;

    final hours = totalTime.inHours;
    final minutes = totalTime.inMinutes.remainder(60);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              context,
              icon: Icons.timer_rounded,
              value: '${hours}h ${minutes}m',
              label: 'Weekly Focus',
            ),
            _buildSummaryItem(
              context,
              icon: Icons.check_circle_rounded,
              value: totalPomodoros.toString(),
              label: 'Pomodoros',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, {required IconData icon, required String value, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weeklyData = context.select((ActionProvider p) => p.completedTasksLast7Days);

    if (weeklyData.values.every((v) => v == 0)) {
      return const SizedBox.shrink(); // Don't show chart if there's no data
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days Completion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weeklyData.values.isEmpty 
                      ? 5.0 
                      : (weeklyData.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(5, double.infinity),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          try {
                            final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                            final dayName = DateFormat('E', 'ko_KR').format(day);
                            return Text(dayName, style: const TextStyle(fontSize: 10));
                          } catch (e) {
                            // Fallback if locale is not available
                            final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                            final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
                            return Text(dayNames[day.weekday % 7], style: const TextStyle(fontSize: 10));
                          }
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value % 5 != 0) return const SizedBox();
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.onSurface.withAlpha((255 * 0.1).round()),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextBreakdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contextData = context.select((ActionProvider p) => p.completedTasksByContextCount);

    if (contextData.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no data
    }

    final total = contextData.values.fold(0, (sum, item) => sum + item);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completed Tasks by Context',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: contextData.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final percentage = (data.value / total) * 100;
                        return PieChartSectionData(
                          color: _chartColors[index % _chartColors.length],
                          value: data.value.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 30,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: contextData.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: _chartColors[index % _chartColors.length],
                            ),
                            const SizedBox(width: 8),
                            Text(data.key),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}