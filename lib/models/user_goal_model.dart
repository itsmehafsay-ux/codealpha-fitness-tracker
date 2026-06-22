class UserGoalModel {
  String userId;
  int dailySteps;
  int dailyCalories;
  int dailyWorkoutMinutes;
  double weeklyDistanceKm;

  UserGoalModel({
    required this.userId,
    this.dailySteps = 10000,
    this.dailyCalories = 500,
    this.dailyWorkoutMinutes = 30,
    this.weeklyDistanceKm = 20.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailySteps': dailySteps,
      'dailyCalories': dailyCalories,
      'dailyWorkoutMinutes': dailyWorkoutMinutes,
      'weeklyDistanceKm': weeklyDistanceKm,
    };
  }

  factory UserGoalModel.fromMap(Map<String, dynamic> map, String userId) {
    return UserGoalModel(
      userId: userId,
      dailySteps: map['dailySteps'] ?? 10000,
      dailyCalories: map['dailyCalories'] ?? 500,
      dailyWorkoutMinutes: map['dailyWorkoutMinutes'] ?? 30,
      weeklyDistanceKm: (map['weeklyDistanceKm'] ?? 20.0).toDouble(),
    );
  }
}
