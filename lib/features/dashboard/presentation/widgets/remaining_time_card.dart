import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class RemainingTimeCard extends ConsumerWidget {
  const RemainingTimeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final remainingMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.remainingMinutes ?? 0),
    );
    final goalMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.dailyGoalMinutes ?? 180),
    );
    final isLow = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.isRemainingTimeLow ?? false),
    );

    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color warningColor = isLow ? colors.error : colors.tertiary;
    final Color cardBg = isLow
        ? colors.errorContainer.withValues(alpha: 0.25)
        : colors.surfaceContainerLow;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isLow ? colors.error.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
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
                    color: warningColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isLow ? Icons.hourglass_bottom_rounded : Icons.timer_outlined,
                    color: warningColor,
                    size: 22,
                  ),
                ),
                const Spacer(),
                if (isLow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'LOW TIME',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'REMAINING TIME',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isLow ? colors.error : null,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMinutes(remainingMinutes),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isLow ? colors.error : null,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Today\'s limit: ${_formatMinutes(goalMinutes)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
    return '${h}h ${m}m';
  }
}
