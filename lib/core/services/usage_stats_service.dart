import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppUsageStats {
  const AppUsageStats({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForegroundMs,
    required this.totalTimeInForegroundMinutes,
    required this.lastTimeUsed,
    required this.sessionCount,
    this.icon,
  });

  factory AppUsageStats.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageStats(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      totalTimeInForegroundMs: (map['totalTimeInForegroundMs'] as num?)?.toInt() ?? 0,
      totalTimeInForegroundMinutes: (map['totalTimeInForegroundMinutes'] as num?)?.toInt() ?? 0,
      lastTimeUsed: (map['lastTimeUsed'] as num?)?.toInt() ?? 0,
      sessionCount: (map['sessionCount'] as num?)?.toInt() ?? 1,
      icon: map['icon'] is Uint8List
          ? map['icon'] as Uint8List
          : map['icon'] is List<dynamic>
              ? Uint8List.fromList(List<int>.from(map['icon'] as List<dynamic>))
              : null,
    );
  }

  final String packageName;
  final String appName;
  final int totalTimeInForegroundMs;
  final int totalTimeInForegroundMinutes;
  final int lastTimeUsed;
  final int sessionCount;
  final Uint8List? icon;

  String get formattedDuration {
    final int h = totalTimeInForegroundMinutes ~/ 60;
    final int m = totalTimeInForegroundMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String get formattedLastUsed {
    if (lastTimeUsed <= 0) return 'Not used recently';
    final DateTime usedTime = DateTime.fromMillisecondsSinceEpoch(lastTimeUsed);
    final Duration diff = DateTime.now().difference(usedTime);
    if (diff.inMinutes < 1) return 'Used just now';
    if (diff.inMinutes < 60) return 'Used ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Used ${diff.inHours}h ago';
    return 'Used ${diff.inDays}d ago';
  }
}

class TodayUsageResult {
  const TodayUsageResult({
    required this.hasPermission,
    required this.totalScreenTimeMinutes,
    required this.weeklyDailyMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyStreak,
    required this.monthlyStreak,
    required this.productivityScore,
    required this.unlockCount,
    required this.appsControlledCount,
    required this.timeSavedMinutes,
    required this.appsUsage,
  });

  final bool hasPermission;
  final int totalScreenTimeMinutes;
  final List<int> weeklyDailyMinutes;
  final int currentStreak;
  final int longestStreak;
  final int weeklyStreak;
  final int monthlyStreak;
  final int productivityScore;
  final int unlockCount;
  final int appsControlledCount;
  final int timeSavedMinutes;
  final List<AppUsageStats> appsUsage;
}

class PeriodUsageResult {
  const PeriodUsageResult({
    required this.hasPermission,
    required this.period,
    required this.totalScreenTimeMinutes,
    required this.totalSessionsCount,
    required this.appsUsage,
  });

  final bool hasPermission;
  final String period;
  final int totalScreenTimeMinutes;
  final int totalSessionsCount;
  final List<AppUsageStats> appsUsage;

  String get formattedTotalDuration {
    final int h = totalScreenTimeMinutes ~/ 60;
    final int m = totalScreenTimeMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class UsageStatsService {
  const UsageStatsService();

  static const MethodChannel _channel = MethodChannel('com.focusguard.app/usage_stats');

  Future<bool> hasUsagePermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? result = await _channel.invokeMethod<bool>('hasUsagePermission');
        return result ?? false;
      } on PlatformException catch (e) {
        debugPrint('Usage permission check error: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> requestUsagePermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('requestUsagePermission');
      } on PlatformException catch (e) {
        debugPrint('Request usage permission error: $e');
      }
    }
  }

  Future<TodayUsageResult> getTodayUsageStats({int dailyGoalMinutes = 180}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final Map<dynamic, dynamic>? res =
            await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getTodayUsageStats',
          <String, dynamic>{'dailyLimitMinutes': dailyGoalMinutes},
        );
        if (res == null) {
          return const TodayUsageResult(
            hasPermission: false,
            totalScreenTimeMinutes: 0,
            weeklyDailyMinutes: <int>[0, 0, 0, 0, 0, 0, 0],
            currentStreak: 0,
            longestStreak: 0,
            weeklyStreak: 0,
            monthlyStreak: 0,
            productivityScore: 85,
            unlockCount: 0,
            appsControlledCount: 0,
            timeSavedMinutes: 0,
            appsUsage: <AppUsageStats>[],
          );
        }

        final bool hasPermission = res['hasPermission'] == true;
        final int totalMinutes = (res['totalScreenTimeMinutes'] as num?)?.toInt() ?? 0;
        final List<dynamic> rawApps = (res['appsUsage'] as List<dynamic>?) ?? <dynamic>[];
        final List<dynamic> rawWeekly = (res['weeklyDailyMinutes'] as List<dynamic>?) ?? <dynamic>[];

        final List<AppUsageStats> apps = rawApps
            .map((dynamic item) => AppUsageStats.fromMap(item as Map<dynamic, dynamic>))
            .toList(growable: false);

        final List<int> weekly = rawWeekly.map((dynamic v) => (v as num).toInt()).toList(growable: false);

        return TodayUsageResult(
          hasPermission: hasPermission,
          totalScreenTimeMinutes: totalMinutes,
          weeklyDailyMinutes: weekly.length == 7 ? weekly : const <int>[0, 0, 0, 0, 0, 0, 0],
          currentStreak: (res['currentStreak'] as num?)?.toInt() ?? 0,
          longestStreak: (res['longestStreak'] as num?)?.toInt() ?? 0,
          weeklyStreak: (res['weeklyStreak'] as num?)?.toInt() ?? 0,
          monthlyStreak: (res['monthlyStreak'] as num?)?.toInt() ?? 0,
          productivityScore: (res['productivityScore'] as num?)?.toInt() ?? 85,
          unlockCount: (res['unlockCount'] as num?)?.toInt() ?? 0,
          appsControlledCount: (res['appsControlledCount'] as num?)?.toInt() ?? 0,
          timeSavedMinutes: (res['timeSavedMinutes'] as num?)?.toInt() ?? 0,
          appsUsage: apps,
        );
      } on PlatformException catch (e) {
        debugPrint('Error fetching usage stats: $e');
      }
    }

    return const TodayUsageResult(
      hasPermission: true,
      totalScreenTimeMinutes: 54,
      weeklyDailyMinutes: <int>[0, 0, 0, 0, 0, 0, 0],
      currentStreak: 1,
      longestStreak: 1,
      weeklyStreak: 1,
      monthlyStreak: 1,
      productivityScore: 85,
      unlockCount: 14,
      appsControlledCount: 5,
      timeSavedMinutes: 45,
      appsUsage: <AppUsageStats>[],
    );
  }

  Future<PeriodUsageResult> getRangeUsageStats({required String range}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final Map<dynamic, dynamic>? res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getRangeUsageStats',
          <String, dynamic>{'range': range},
        );

        if (res != null) {
          final bool hasPermission = res['hasPermission'] == true;
          final int totalMinutes = (res['totalScreenTimeMinutes'] as num?)?.toInt() ?? 0;
          final int totalSessions = (res['totalSessionsCount'] as num?)?.toInt() ?? 0;
          final List<dynamic> rawApps = (res['appsUsage'] as List<dynamic>?) ?? <dynamic>[];

          final List<AppUsageStats> apps = rawApps
              .map((dynamic item) => AppUsageStats.fromMap(item as Map<dynamic, dynamic>))
              .toList(growable: false);

          return PeriodUsageResult(
            hasPermission: hasPermission,
            period: range,
            totalScreenTimeMinutes: totalMinutes,
            totalSessionsCount: totalSessions,
            appsUsage: apps,
          );
        }
      } on PlatformException catch (e) {
        debugPrint('Error fetching range usage stats: $e');
      }
    }

    return PeriodUsageResult(
      hasPermission: true,
      period: range,
      totalScreenTimeMinutes: range == 'monthly' ? 1420 : range == 'weekly' ? 340 : 54,
      totalSessionsCount: range == 'monthly' ? 420 : range == 'weekly' ? 120 : 18,
      appsUsage: const <AppUsageStats>[],
    );
  }

  Future<PeriodUsageResult> getDayUsageStats({required int dayStartMs}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final Map<dynamic, dynamic>? res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getDayUsageStats',
          <String, dynamic>{'dayStartMs': dayStartMs},
        );

        if (res != null) {
          final bool hasPermission = res['hasPermission'] == true;
          final int totalMinutes = (res['totalScreenTimeMinutes'] as num?)?.toInt() ?? 0;
          final int totalSessions = (res['totalSessionsCount'] as num?)?.toInt() ?? 0;
          final List<dynamic> rawApps = (res['appsUsage'] as List<dynamic>?) ?? <dynamic>[];

          final List<AppUsageStats> apps = rawApps
              .map((dynamic item) => AppUsageStats.fromMap(item as Map<dynamic, dynamic>))
              .toList(growable: false);

          return PeriodUsageResult(
            hasPermission: hasPermission,
            period: 'day',
            totalScreenTimeMinutes: totalMinutes,
            totalSessionsCount: totalSessions,
            appsUsage: apps,
          );
        }
      } on PlatformException catch (e) {
        debugPrint('Error fetching day usage stats: $e');
      }
    }

    return const PeriodUsageResult(
      hasPermission: true,
      period: 'day',
      totalScreenTimeMinutes: 0,
      totalSessionsCount: 0,
      appsUsage: <AppUsageStats>[],
    );
  }
}
