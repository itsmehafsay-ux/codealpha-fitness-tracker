import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/activity_model.dart';
import '../models/user_goal_model.dart';
import 'add_activity_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDark;
  const HomeScreen({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  int _currentIndex = 0;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _userName => FirebaseAuth.instance.currentUser?.displayName ?? 'User';

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        userId: _userId,
        userName: _userName,
        firestoreService: _firestoreService,
        isDark: _isDark,
        onToggleTheme: (val) {
          setState(() => _isDark = val);
          widget.onToggleTheme(val);
        },
        onLogout: _logout,
      ),
      HistoryScreen(userId: _userId),
      StatsScreen(userId: _userId),
      ProfileScreen(
        userId: _userId,
        userName: _userName,
        isDark: _isDark,
        onToggleTheme: (val) {
          setState(() => _isDark = val);
          widget.onToggleTheme(val);
        },
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddActivityScreen(userId: _userId)),
              ),
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Log Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }
}

class _DashboardTab extends StatelessWidget {
  final String userId;
  final String userName;
  final FirestoreService firestoreService;
  final bool isDark;
  final Function(bool) onToggleTheme;
  final VoidCallback onLogout;

  const _DashboardTab({
    required this.userId,
    required this.userName,
    required this.firestoreService,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserGoalModel>(
      future: firestoreService.getGoals(userId),
      builder: (context, goalSnap) {
        final goals = goalSnap.data ?? UserGoalModel(userId: userId);
        return StreamBuilder<List<ActivityModel>>(
          stream: firestoreService.getActivities(userId),
          builder: (context, snap) {
            final activities = snap.data ?? [];
            final today = DateTime.now();
            final todayActivities = activities.where((a) =>
              a.date.year == today.year &&
              a.date.month == today.month &&
              a.date.day == today.day).toList();

            final totalSteps = todayActivities.fold(0, (s, a) => s + a.steps);
            final totalCalories = todayActivities.fold(0, (s, a) => s + a.calories);
            final totalMinutes = todayActivities.fold(0, (s, a) => s + a.durationMinutes);

            final stepsPercent = (totalSteps / goals.dailySteps).clamp(0.0, 1.0);
            final calPercent = (totalCalories / goals.dailyCalories).clamp(0.0, 1.0);
            final minPercent = (totalMinutes / goals.dailyWorkoutMinutes).clamp(0.0, 1.0);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF3B3AC7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $userName 👋',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Stay consistent today!',
                            style: TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  actions: [
                    Switch(
                      value: isDark,
                      onChanged: onToggleTheme,
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionTitle(title: "Today's Progress"),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CircularStat(label: 'Steps', value: totalSteps, goal: goals.dailySteps,
                              percent: stepsPercent, color: const Color(0xFF6C63FF), icon: Icons.directions_walk),
                          _CircularStat(label: 'Calories', value: totalCalories, goal: goals.dailyCalories,
                              percent: calPercent, color: Colors.orangeAccent, icon: Icons.local_fire_department),
                          _CircularStat(label: 'Minutes', value: totalMinutes, goal: goals.dailyWorkoutMinutes,
                              percent: minPercent, color: Colors.greenAccent.shade400, icon: Icons.timer),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'Quick Stats'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatCard(
                            icon: Icons.local_fire_department,
                            color: Colors.deepOrange,
                            label: 'Calories Burned',
                            value: '$totalCalories kcal',
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(
                            icon: Icons.directions_walk,
                            color: const Color(0xFF6C63FF),
                            label: 'Steps Today',
                            value: '$totalSteps',
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatCard(
                            icon: Icons.fitness_center,
                            color: Colors.teal,
                            label: 'Workouts Today',
                            value: '${todayActivities.length}',
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(
                            icon: Icons.timer,
                            color: Colors.amber,
                            label: 'Active Minutes',
                            value: '$totalMinutes min',
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'Recent Activities'),
                      const SizedBox(height: 12),
                      if (activities.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.directions_run, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No activities yet. Start moving!',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      else
                        ...activities.take(5).map((a) => _ActivityTile(activity: a)),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _CircularStat extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final double percent;
  final Color color;
  final IconData icon;

  const _CircularStat({
    required this.label, required this.value, required this.goal,
    required this.percent, required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 48,
          lineWidth: 8,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text('${(percent * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          progressColor: color,
          backgroundColor: color.withOpacity(0.15),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('$value / $goal', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  const _ActivityTile({required this.activity});

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running': return Icons.directions_run;
      case 'walking': return Icons.directions_walk;
      case 'cycling': return Icons.directions_bike;
      case 'swimming': return Icons.pool;
      case 'gym': return Icons.fitness_center;
      case 'yoga': return Icons.self_improvement;
      default: return Icons.sports;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'running': return Colors.deepOrange;
      case 'walking': return const Color(0xFF6C63FF);
      case 'cycling': return Colors.teal;
      case 'swimming': return Colors.blue;
      case 'gym': return Colors.red;
      case 'yoga': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor(activity.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIcon(activity.type), color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.type,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${activity.durationMinutes} min • ${activity.calories} kcal • ${activity.steps} steps',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(activity.intensity,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
