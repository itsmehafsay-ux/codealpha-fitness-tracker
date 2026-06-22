import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/activity_model.dart';

class StatsScreen extends StatefulWidget {
  final String userId;
  const StatsScreen({super.key, required this.userId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late TabController _tabController;
  String _selectedMetric = 'Calories';
  final List<String> _metrics = ['Calories', 'Steps', 'Duration', 'Distance'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FlSpot> _buildSpots(List<ActivityModel> activities, String metric) {
    final now = DateTime.now();
    final Map<int, double> dayData = {};
    for (int i = 6; i >= 0; i--) {
      dayData[i] = 0;
    }
    for (final a in activities) {
      final diff = now.difference(a.date).inDays;
      if (diff <= 6) {
        final key = 6 - diff;
        switch (metric) {
          case 'Calories': dayData[key] = (dayData[key] ?? 0) + a.calories; break;
          case 'Steps': dayData[key] = (dayData[key] ?? 0) + a.steps; break;
          case 'Duration': dayData[key] = (dayData[key] ?? 0) + a.durationMinutes; break;
          case 'Distance': dayData[key] = (dayData[key] ?? 0) + a.distanceKm; break;
        }
      }
    }
    return dayData.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  Map<String, double> _buildTypeBreakdown(List<ActivityModel> activities) {
    final Map<String, double> data = {};
    for (final a in activities) {
      data[a.type] = (data[a.type] ?? 0) + a.calories;
    }
    return data;
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'running': return Colors.deepOrange;
      case 'walking': return const Color(0xFF6C63FF);
      case 'cycling': return Colors.teal;
      case 'swimming': return Colors.blue;
      case 'gym': return Colors.red;
      case 'yoga': return Colors.purple;
      case 'football': return Colors.green;
      case 'basketball': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3B3AC7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Weekly Trend'),
            Tab(text: 'Breakdown'),
          ],
        ),
      ),
      body: FutureBuilder<List<ActivityModel>>(
        future: _firestoreService.getActivitiesForWeek(widget.userId),
        builder: (context, snap) {
          final activities = snap.data ?? [];
          final spots = _buildSpots(activities, _selectedMetric);
          final breakdown = _buildTypeBreakdown(activities);
          final totalCalories = activities.fold(0, (s, a) => s + a.calories);
          final totalSteps = activities.fold(0, (s, a) => s + a.steps);
          final totalMinutes = activities.fold(0, (s, a) => s + a.durationMinutes);
          final totalDistance = activities.fold(0.0, (s, a) => s + a.distanceKm);

          return TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This Week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _MiniStatCard(label: 'Calories', value: '$totalCalories', color: Colors.deepOrange, icon: Icons.local_fire_department)),
                        const SizedBox(width: 10),
                        Expanded(child: _MiniStatCard(label: 'Steps', value: '$totalSteps', color: const Color(0xFF6C63FF), icon: Icons.directions_walk)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _MiniStatCard(label: 'Minutes', value: '$totalMinutes', color: Colors.teal, icon: Icons.timer)),
                        const SizedBox(width: 10),
                        Expanded(child: _MiniStatCard(label: 'Distance', value: '${totalDistance.toStringAsFixed(1)} km', color: Colors.amber, icon: Icons.straighten)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Daily Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _metrics.map((m) {
                          final isSelected = _selectedMetric == m;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMetric = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3B3AC7)])
                                    : null,
                                color: isSelected ? null : (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(m,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: spots.isEmpty || spots.every((s) => s.y == 0)
                          ? const Center(child: Text('No data for this week'))
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (v) => FlLine(
                                    color: Colors.grey.withOpacity(0.15),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                                          style: const TextStyle(fontSize: 10))),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, _) {
                                        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                                        final now = DateTime.now();
                                        final idx = v.toInt();
                                        final day = now.subtract(Duration(days: 6 - idx));
                                        final dayName = days[day.weekday - 1];
                                        return Text(dayName, style: const TextStyle(fontSize: 10));
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6C63FF), Color(0xFF3B3AC7)],
                                    ),
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                        radius: 4,
                                        color: const Color(0xFF6C63FF),
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF6C63FF).withOpacity(0.3),
                                          const Color(0xFF6C63FF).withOpacity(0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calories by Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (breakdown.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No data yet'),
                      ))
                    else
                      Container(
                        height: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: breakdown.entries.map((e) {
                              final total = breakdown.values.fold(0.0, (a, b) => a + b);
                              final pct = (e.value / total * 100).toStringAsFixed(1);
                              return PieChartSectionData(
                                color: _getColor(e.key),
                                value: e.value,
                                title: '$pct%',
                                radius: 60,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text('Legend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...breakdown.entries.map((e) {
                      final color = _getColor(e.key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(width: 16, height: 16,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${e.value.toInt()} kcal',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
