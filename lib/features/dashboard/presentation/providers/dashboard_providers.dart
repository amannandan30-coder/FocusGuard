import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/content_blocker_service.dart';
import '../../../../core/services/usage_stats_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../content_blocker/presentation/providers/content_blocker_providers.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/entities/recent_activity_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'focus_session_providers.dart';

final Provider<UsageStatsService> usageStatsServiceProvider =
    Provider<UsageStatsService>((Ref ref) => const UsageStatsService());

class DailyGoalNotifier extends StateNotifier<int> {
  DailyGoalNotifier() : super(180) {
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? saved = prefs.getInt('user_daily_goal_minutes');
      if (saved != null && saved > 0) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setGoal(int minutes) async {
    state = minutes;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_daily_goal_minutes', minutes);
    } catch (_) {}
  }
}

final StateNotifierProvider<DailyGoalNotifier, int> dailyGoalMinutesProvider =
    StateNotifierProvider<DailyGoalNotifier, int>((Ref ref) => DailyGoalNotifier());

final StreamProvider<TodayUsageResult> todayLiveUsageProvider =
    StreamProvider<TodayUsageResult>((Ref ref) async* {
  final int goalMinutes = ref.watch(dailyGoalMinutesProvider);
  final UsageStatsService service = ref.watch(usageStatsServiceProvider);

  yield await service.getTodayUsageStats(dailyGoalMinutes: goalMinutes);

  await for (final _ in Stream<void>.periodic(const Duration(seconds: 10))) {
    yield await service.getTodayUsageStats(dailyGoalMinutes: goalMinutes);
  }
});

final StreamProviderFamily<PeriodUsageResult, String> periodUsageProvider =
    StreamProvider.family<PeriodUsageResult, String>((Ref ref, String period) async* {
  final UsageStatsService service = ref.watch(usageStatsServiceProvider);

  yield await service.getRangeUsageStats(range: period);

  await for (final _ in Stream<void>.periodic(const Duration(seconds: 10))) {
    yield await service.getRangeUsageStats(range: period);
  }
});

final StreamProviderFamily<PeriodUsageResult, int> specificDayUsageProvider =
    StreamProvider.family<PeriodUsageResult, int>((Ref ref, int dayStartMs) async* {
  final UsageStatsService service = ref.watch(usageStatsServiceProvider);

  yield await service.getDayUsageStats(dayStartMs: dayStartMs);

  await for (final _ in Stream<void>.periodic(const Duration(seconds: 10))) {
    yield await service.getDayUsageStats(dayStartMs: dayStartMs);
  }
});

final Provider<DashboardRepository> dashboardRepositoryProvider =
    Provider<DashboardRepository>((Ref ref) {
  return DashboardRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final StreamProviderFamily<DashboardMetricsEntity, String> dashboardMetricsStreamProvider =
    StreamProvider.family<DashboardMetricsEntity, String>((Ref ref, String userId) {
  final Stream<DashboardMetricsEntity> stream =
      ref.watch(dashboardRepositoryProvider).watchDashboardMetrics(userId);

  final AsyncValue<TodayUsageResult> liveUsage = ref.watch(todayLiveUsageProvider);
  final int targetGoalMinutes = ref.watch(dailyGoalMinutesProvider);
  final FocusSessionState focusState = ref.watch(focusSessionProvider);

  return stream.map((DashboardMetricsEntity metrics) {
    if (liveUsage.hasValue && liveUsage.value!.hasPermission) {
      final int liveMinutes = liveUsage.value!.totalScreenTimeMinutes;
      final List<int> liveWeekly = liveUsage.value!.weeklyDailyMinutes;
      final int totalWeeklyMinutes = liveWeekly.fold<int>(0, (int sum, int m) => sum + m);

      return DashboardMetricsEntity(
        todayScreenMinutes: liveMinutes,
        dailyGoalMinutes: targetGoalMinutes,
        weeklyProgressMinutes: totalWeeklyMinutes > 0 ? totalWeeklyMinutes : metrics.weeklyProgressMinutes,
        weeklyGoalMinutes: targetGoalMinutes * 7,
        currentStreak: liveUsage.value!.currentStreak,
        longestStreak: liveUsage.value!.longestStreak,
        weeklyStreak: liveUsage.value!.weeklyStreak,
        monthlyStreak: liveUsage.value!.monthlyStreak,
        productivityScore: liveUsage.value!.productivityScore,
        isFocusActive: focusState.isActive,
        weeklyDailyMinutes: liveWeekly,
        unlockCount: liveUsage.value!.unlockCount,
        focusSessionsCount: focusState.completedSessionsToday,
        appsControlledCount: liveUsage.value!.appsControlledCount,
        timeSavedMinutes: liveUsage.value!.timeSavedMinutes,
      );
    }
    return metrics;
  });
});

typedef DashboardMetrics = DashboardMetricsEntity;
final StreamProviderFamily<DashboardMetricsEntity, String> dashboardMetricsProvider =
    dashboardMetricsStreamProvider;

final StreamProviderFamily<List<RecentActivityEntity>, String> recentActivitiesStreamProvider =
    StreamProvider.family<List<RecentActivityEntity>, String>((Ref ref, String userId) {
  final Stream<List<RecentActivityEntity>> firestoreStream =
      ref.watch(dashboardRepositoryProvider).watchRecentActivities(userId);
  final AsyncValue<TodayUsageResult> liveUsage = ref.watch(todayLiveUsageProvider);
  final AsyncValue<ContentBlockerConfig> blockerConfig = ref.watch(contentBlockerProvider);

  return firestoreStream.map((List<RecentActivityEntity> firestoreList) {
    final List<RecentActivityEntity> activities = <RecentActivityEntity>[];

    // 1. User-logged activities from Firestore
    activities.addAll(firestoreList);

    // 2. Real-time Blocker Event
    if (blockerConfig.hasValue && blockerConfig.value!.blockedCountToday > 0) {
      final int count = blockerConfig.value!.blockedCountToday;
      activities.add(
        RecentActivityEntity(
          id: 'blocker_live_summary',
          title: 'Blocked $count Distractions Today',
          subtitle: 'Shorts & Reels shields active',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          type: 'block',
        ),
      );
    }

    // 3. Top App Used Today Event
    if (liveUsage.hasValue && liveUsage.value!.appsUsage.isNotEmpty) {
      final AppUsageStats topApp = liveUsage.value!.appsUsage.first;
      if (topApp.totalTimeInForegroundMinutes > 0) {
        activities.add(
          RecentActivityEntity(
            id: 'top_app_${topApp.packageName}',
            title: 'Top App: ${topApp.appName}',
            subtitle: 'Used for ${topApp.formattedDuration} today',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              topApp.lastTimeUsed > 0 ? topApp.lastTimeUsed : DateTime.now().millisecondsSinceEpoch,
            ),
            type: 'session',
          ),
        );
      }
    }

    // 4. Live Unlocks Event
    if (liveUsage.hasValue && liveUsage.value!.unlockCount > 0) {
      final int unlocks = liveUsage.value!.unlockCount;
      activities.add(
        RecentActivityEntity(
          id: 'live_unlock_summary',
          title: '$unlocks Phone Pickups Today',
          subtitle: unlocks <= 25 ? 'Mindful pickup level maintained' : 'High phone pickup frequency',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          type: 'streak',
        ),
      );
    }

    // 5. Daily Goal Progress Event
    if (liveUsage.hasValue) {
      final int totalMinutes = liveUsage.value!.totalScreenTimeMinutes;
      final int savedMinutes = liveUsage.value!.timeSavedMinutes;
      if (savedMinutes > 0) {
        activities.add(
          RecentActivityEntity(
            id: 'time_saved_summary',
            title: 'Saved ${savedMinutes}m Screen Time',
            subtitle: 'Staying within daily limit',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            type: 'goal',
          ),
        );
      } else if (totalMinutes > 0) {
        activities.add(
          RecentActivityEntity(
            id: 'screen_time_summary',
            title: 'Tracked ${totalMinutes}m Total Usage',
            subtitle: 'Live screen time monitoring',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            type: 'session',
          ),
        );
      }
    }

    // Sort by timestamp descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Deduplicate by ID
    final Set<String> seenIds = <String>{};
    final List<RecentActivityEntity> result = <RecentActivityEntity>[];
    for (final RecentActivityEntity item in activities) {
      if (seenIds.add(item.id)) {
        result.add(item);
      }
    }

    return result;
  });
});

final StateProvider<int> bottomNavIndexProvider = StateProvider<int>((Ref ref) => 0);

final Provider<String> dailyQuoteProvider = Provider<String>((Ref ref) {
  const List<String> quotes = <String>[
    'Small choices, repeated every day, create the focus you are proud of.',
    'You do not need a perfect day. You only need the next focused moment.',
    'Focus is a muscle. The more you practice, the stronger it gets.',
    'Small improvements every day lead to remarkable results.',
    'Disconnect to reconnect with what truly matters.',
    'Your time is your life. Spend it intentionally.',
    'Master your focus, master your day.',
  ];
  final int dayIndex = DateTime.now().day % quotes.length;
  return quotes[dayIndex];
});

class FocusSessionController extends StateNotifier<AsyncValue<void>> {
  FocusSessionController(this._repository, this._userId) : super(const AsyncData<void>(null));

  final DashboardRepository _repository;
  final String _userId;

  Future<void> setFocusActive(bool active) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await _repository.setFocusActive(_userId, active);
    });
  }
}

final StateNotifierProviderFamily<FocusSessionController, AsyncValue<void>, String>
    focusSessionControllerProvider = StateNotifierProvider.family<FocusSessionController, AsyncValue<void>, String>(
  (Ref ref, String userId) {
    return FocusSessionController(ref.watch(dashboardRepositoryProvider), userId);
  },
);
