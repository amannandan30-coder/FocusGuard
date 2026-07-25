import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class DailyGoalCard extends ConsumerWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final goalMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.dailyGoalMinutes ?? 180),
    );
    final progress = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.dailyProgress ?? 0.0),
    );
    final isCompleted = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.isGoalCompleted ?? true),
    );

    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color statusColor = isCompleted ? Colors.teal : colors.primary;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.flag_rounded, color: statusColor, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'TODAY\'S GOAL',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stay below ${_formatMinutes(goalMinutes)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isCompleted ? 'Great job staying on track today!' : 'Keep monitoring your app time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double val, Widget? child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: val,
                    minHeight: 7,
                    color: statusColor,
                    backgroundColor: statusColor.withValues(alpha: 0.14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
