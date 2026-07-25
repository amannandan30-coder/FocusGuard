import 'dart:math' as math;

class DashboardMetricsEntity {
  const DashboardMetricsEntity({
    required this.todayScreenMinutes,
    required this.dailyGoalMinutes,
    required this.weeklyProgressMinutes,
    required this.weeklyGoalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyStreak,
    required this.monthlyStreak,
    required this.productivityScore,
    required this.isFocusActive,
    required this.weeklyDailyMinutes,
    required this.unlockCount,
    required this.focusSessionsCount,
    required this.appsControlledCount,
    required this.timeSavedMinutes,
  });

  factory DashboardMetricsEntity.fromMap(Map<String, dynamic>? data) {
    final List<dynamic>? weeklyList = data?['weeklyDailyMinutes'] as List<dynamic>?;
    final int today = _readInt(data?['todayScreenMinutes'], fallback: 138);
    final int goal = _readInt(data?['dailyGoalMinutes'], fallback: 180);

    return DashboardMetricsEntity(
      todayScreenMinutes: today,
      dailyGoalMinutes: goal,
      weeklyProgressMinutes: _readInt(data?['weeklyProgressMinutes'], fallback: 528),
      weeklyGoalMinutes: _readInt(data?['weeklyGoalMinutes'], fallback: 900),
      currentStreak: _readInt(data?['currentStreak'], fallback: 8),
      longestStreak: _readInt(data?['longestStreak'], fallback: 14),
      weeklyStreak: _readInt(data?['weeklyStreak'], fallback: 5),
      monthlyStreak: _readInt(data?['monthlyStreak'], fallback: 21),
      productivityScore: _readInt(data?['productivityScore'], fallback: 92),
      isFocusActive: data?['isFocusActive'] == true,
      weeklyDailyMinutes: weeklyList == null
          ? const <int>[46, 68, 82, 61, 93, 71, 107]
          : weeklyList.map((dynamic v) => _readInt(v)).toList(growable: false),
      unlockCount: _readInt(data?['unlockCount'], fallback: 42),
      focusSessionsCount: _readInt(data?['focusSessionsCount'], fallback: 6),
      appsControlledCount: _readInt(data?['appsControlledCount'], fallback: 12),
      timeSavedMinutes: _readInt(data?['timeSavedMinutes'], fallback: 45),
    );
  }

  final int todayScreenMinutes;
  final int dailyGoalMinutes;
  final int weeklyProgressMinutes;
  final int weeklyGoalMinutes;
  final int currentStreak;
  final int longestStreak;
  final int weeklyStreak;
  final int monthlyStreak;
  final int productivityScore;
  final bool isFocusActive;
  final List<int> weeklyDailyMinutes;
  final int unlockCount;
  final int focusSessionsCount;
  final int appsControlledCount;
  final int timeSavedMinutes;

  int get remainingMinutes => math.max(0, dailyGoalMinutes - todayScreenMinutes);
  double get dailyProgress => dailyGoalMinutes <= 0 ? 0.0 : (todayScreenMinutes / dailyGoalMinutes).clamp(0.0, 1.0);
  double get weeklyProgress => weeklyGoalMinutes <= 0 ? 0.0 : (weeklyProgressMinutes / weeklyGoalMinutes).clamp(0.0, 1.0);
  bool get isRemainingTimeLow => remainingMinutes <= 45;
  bool get isGoalCompleted => todayScreenMinutes <= dailyGoalMinutes;

  String get productivityCategory {
    if (productivityScore >= 85) return 'Excellent';
    if (productivityScore >= 70) return 'Good';
    if (productivityScore >= 50) return 'Average';
    return 'Needs Improvement';
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    return fallback;
  }
}
