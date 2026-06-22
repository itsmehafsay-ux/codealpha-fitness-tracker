import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/activity_model.dart';

class AddActivityScreen extends StatefulWidget {
  final String userId;
  final ActivityModel? existingActivity;
  const AddActivityScreen({super.key, required this.userId, this.existingActivity});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _caloriesController = TextEditingController();
  final _stepsController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'Running';
  String _selectedIntensity = 'Medium';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  final List<String> _activityTypes = [
    'Running', 'Walking', 'Cycling', 'Swimming', 'Gym', 'Yoga', 'Football', 'Basketball', 'Other'
  ];
  final List<String> _intensities = ['Low', 'Medium', 'High'];

  final Map<String, IconData> _activityIcons = {
    'Running': Icons.directions_run,
    'Walking': Icons.directions_walk,
    'Cycling': Icons.directions_bike,
    'Swimming': Icons.pool,
    'Gym': Icons.fitness_center,
    'Yoga': Icons.self_improvement,
    'Football': Icons.sports_soccer,
    'Basketball': Icons.sports_basketball,
    'Other': Icons.sports,
  };

  final Map<String, Color> _activityColors = {
    'Running': Colors.deepOrange,
    'Walking': Color(0xFF6C63FF),
    'Cycling': Colors.teal,
    'Swimming': Colors.blue,
    'Gym': Colors.red,
    'Yoga': Colors.purple,
    'Football': Colors.green,
    'Basketball': Colors.orange,
    'Other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingActivity != null) {
      final a = widget.existingActivity!;
      _selectedType = a.type;
      _selectedIntensity = a.intensity;
      _selectedDate = a.date;
      _caloriesController.text = a.calories.toString();
      _stepsController.text = a.steps.toString();
      _durationController.text = a.durationMinutes.toString();
      _distanceController.text = a.distanceKm.toString();
      _notesController.text = a.notes;
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _stepsController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final activity = ActivityModel(
        id: widget.existingActivity?.id,
        userId: widget.userId,
        type: _selectedType,
        intensity: _selectedIntensity,
        durationMinutes: int.parse(_durationController.text.trim()),
        calories: int.parse(_caloriesController.text.trim()),
        steps: int.parse(_stepsController.text.trim()),
        distanceKm: double.tryParse(_distanceController.text.trim()) ?? 0.0,
        date: _selectedDate,
        notes: _notesController.text.trim(),
      );
      if (widget.existingActivity != null) {
        await _firestoreService.updateActivity(activity);
      } else {
        await _firestoreService.addActivity(activity);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _activityColors[_selectedType] ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingActivity != null ? 'Edit Activity' : 'Log Activity',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activity Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _activityTypes.length,
                  itemBuilder: (context, i) {
                    final type = _activityTypes[i];
                    final isSelected = _selectedType == type;
                    final c = _activityColors[type] ?? Colors.grey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [c, c.withOpacity(0.7)])
                              : null,
                          color: isSelected ? null : (isDark ? Colors.white10 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_activityIcons[type], color: isSelected ? Colors.white : c, size: 28),
                            const SizedBox(height: 6),
                            Text(type,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : null)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text('Intensity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: _intensities.map((intensity) {
                  final isSelected = _selectedIntensity == intensity;
                  final c = intensity == 'Low' ? Colors.green : intensity == 'Medium' ? Colors.orange : Colors.red;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIntensity = intensity),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? c : (isDark ? Colors.white10 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Center(
                          child: Text(intensity,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : null)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                        controller: _durationController, label: 'Duration (min)', icon: Icons.timer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                        controller: _caloriesController, label: 'Calories', icon: Icons.local_fire_department),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                        controller: _stepsController, label: 'Steps', icon: Icons.directions_walk),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                        controller: _distanceController, label: 'Distance (km)', icon: Icons.straighten, isDouble: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFF6C63FF)),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.existingActivity != null ? 'Update Activity' : 'Save Activity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDouble = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (!isDouble && int.tryParse(v) == null) return 'Invalid';
        if (isDouble && double.tryParse(v) == null) return 'Invalid';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
      ),
    );
  }
}
