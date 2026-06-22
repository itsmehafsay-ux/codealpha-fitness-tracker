class ActivityModel {
  String? id;
  String userId;
  String type;
  String intensity;
  int durationMinutes;
  int calories;
  int steps;
  double distanceKm;
  DateTime date;
  String notes;

  ActivityModel({
    this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    required this.calories,
    required this.steps,
    this.intensity = 'Medium',
    this.distanceKm = 0.0,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'intensity': intensity,
      'durationMinutes': durationMinutes,
      'calories': calories,
      'steps': steps,
      'distanceKm': distanceKm,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      intensity: map['intensity'] ?? 'Medium',
      durationMinutes: map['durationMinutes'] ?? 0,
      calories: map['calories'] ?? 0,
      steps: map['steps'] ?? 0,
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
    );
  }
}
