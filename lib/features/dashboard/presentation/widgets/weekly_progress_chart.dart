import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../screens/weekly_detail_screen.dart';

class WeeklyProgressChart extends ConsumerWidget {
  const WeeklyProgressChart({super.key});

  void _openWeeklyDetail(BuildContext context, int dayIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeeklyDetailScreen(initialDayIndex: dayIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final weeklyDailyMinutes = ref.watch(
      dashboardMetricsProvider(userId).select(
        (AsyncValue<DashboardMetrics> m) => m.valueOrNull?.weeklyDailyMinutes ?? const <int>[0, 0, 0, 0, 0, 0, 0],
      ),
    );
    final weeklyProgressMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.weeklyProgressMinutes ?? 0),
    );
    final weeklyGoalMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.weeklyGoalMinutes ?? 1260),
    );

    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<String> days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final int maxMinutes = weeklyDailyMinutes.fold<int>(1, (int max, int val) => val > max ? val : max);
    final int currentWeekdayIndex = DateTime.now().weekday - 1;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => _openWeeklyDetail(context, currentWeekdayIndex),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'WEEKLY PROGRESS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: colors.primary, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatMinutes(weeklyProgressMinutes)} of ${_formatMinutes(weeklyGoalMinutes)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 20),

              // Animated Interactive Bar Chart
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(days.length, (int index) {
                    final int value = index < weeklyDailyMinutes.length ? weeklyDailyMinutes[index] : 0;
                    final bool isToday = index == currentWeekdayIndex;
                    final double barHeightRatio = (value / maxMinutes).clamp(0.1, 1.0);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => _openWeeklyDetail(context, index),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                _shortMinutes(value),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                  color: isToday ? colors.primary : colors.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: barHeightRatio),
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutQuart,
                                    builder: (BuildContext context, double heightRatio, Widget? child) {
                                      return FractionallySizedBox(
                                        heightFactor: heightRatio,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isToday ? colors.primary : colors.primary.withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                days[index],
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isToday ? colors.primary : colors.onSurfaceVariant,
                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  static String _shortMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h${m > 0 ? '${m}m' : ''}';
  }
}
