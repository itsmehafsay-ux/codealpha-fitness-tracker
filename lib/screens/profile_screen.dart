import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_goal_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isDark;
  final Function(bool) onToggleTheme;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _minutesController = TextEditingController();
  final _distanceController = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  UserGoalModel? _goals;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    final goals = await _firestoreService.getGoals(widget.userId);
    setState(() {
      _goals = goals;
      _stepsController.text = goals.dailySteps.toString();
      _caloriesController.text = goals.dailyCalories.toString();
      _minutesController.text = goals.dailyWorkoutMinutes.toString();
      _distanceController.text = goals.weeklyDistanceKm.toString();
      _loading = false;
    });
  }

  Future<void> _saveGoals() async {
    setState(() => _saving = true);
    try {
      final updated = UserGoalModel(
        userId: widget.userId,
        dailySteps: int.tryParse(_stepsController.text) ?? 10000,
        dailyCalories: int.tryParse(_caloriesController.text) ?? 500,
        dailyWorkoutMinutes: int.tryParse(_minutesController.text) ?? 30,
        weeklyDistanceKm: double.tryParse(_distanceController.text) ?? 20.0,
      );
      await _firestoreService.saveGoals(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      widget.onLogout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
              onToggleTheme: widget.onToggleTheme, isDark: widget.isDark),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _minutesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Goals', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3B3AC7)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.userName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'FitTrack Pro Member',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'Daily Goals', icon: Icons.flag_outlined),
                  const SizedBox(height: 14),
                  _GoalField(
                    controller: _stepsController,
                    label: 'Daily Steps Goal',
                    icon: Icons.directions_walk,
                    color: const Color(0xFF6C63FF),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _GoalField(
                    controller: _caloriesController,
                    label: 'Daily Calories Goal',
                    icon: Icons.local_fire_department,
                    color: Colors.deepOrange,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _GoalField(
                    controller: _minutesController,
                    label: 'Daily Workout Minutes',
                    icon: Icons.timer,
                    color: Colors.teal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _GoalField(
                    controller: _distanceController,
                    label: 'Weekly Distance (km)',
                    icon: Icons.straighten,
                    color: Colors.amber,
                    isDark: isDark,
                    isDouble: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF3B3AC7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveGoals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, color: Colors.white),
                        label: Text(
                          _saving ? 'Saving...' : 'Save Goals',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(widget.isDark ? 'Currently dark' : 'Currently light',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      secondary: Icon(
                        widget.isDark ? Icons.dark_mode : Icons.light_mode,
                        color: const Color(0xFF6C63FF),
                      ),
                      value: widget.isDark,
                      activeColor: const Color(0xFF6C63FF),
                      onChanged: widget.onToggleTheme,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'Account', icon: Icons.manage_accounts_outlined),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text('Logout',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                      subtitle: Text('Sign out of your account',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                      onTap: _confirmLogout,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Text('FitTrack Pro v1.0.0',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isDouble;

  const _GoalField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isDouble = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}
