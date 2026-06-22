import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../models/user_goal_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addActivity(ActivityModel activity) async {
    await _db
        .collection('fitness_users')
        .doc(activity.userId)
        .collection('activities')
        .add(activity.toMap());
  }

  Future<void> updateActivity(ActivityModel activity) async {
    await _db
        .collection('fitness_users')
        .doc(activity.userId)
        .collection('activities')
        .doc(activity.id)
        .update(activity.toMap());
  }

  Future<void> deleteActivity(String userId, String activityId) async {
    await _db
        .collection('fitness_users')
        .doc(userId)
        .collection('activities')
        .doc(activityId)
        .delete();
  }

  Stream<List<ActivityModel>> getActivities(String userId) {
    return _db
        .collection('fitness_users')
        .doc(userId)
        .collection('activities')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<ActivityModel>> getActivitiesForDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _db
        .collection('fitness_users')
        .doc(userId)
        .collection('activities')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<ActivityModel>> getActivitiesForWeek(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final snapshot = await _db
        .collection('fitness_users')
        .doc(userId)
        .collection('activities')
        .where('date', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> saveGoals(UserGoalModel goals) async {
    await _db
        .collection('fitness_users')
        .doc(goals.userId)
        .collection('settings')
        .doc('goals')
        .set(goals.toMap());
  }

  Future<UserGoalModel> getGoals(String userId) async {
    final doc = await _db
        .collection('fitness_users')
        .doc(userId)
        .collection('settings')
        .doc('goals')
        .get();
    if (doc.exists && doc.data() != null) {
      return UserGoalModel.fromMap(doc.data()!, userId);
    }
    return UserGoalModel(userId: userId);
  }

  Future<int> getStreak(String userId) async {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (int i = 0; i < 100; i++) {
      final activities = await getActivitiesForDate(userId, checkDate);
      if (activities.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
