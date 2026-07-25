import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/usage_stats_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class ScreenTimeCard extends ConsumerWidget {
  const ScreenTimeCard({super.key, this.isWide = false});

  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final minutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.todayScreenMinutes ?? 0),
    );
    final progress = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.dailyProgress ?? 0.0),
    );


    final AsyncValue<TodayUsageResult> liveUsageAsync = ref.watch(todayLiveUsageProvider);
    final bool hasPermission = liveUsageAsync.valueOrNull?.hasPermission ?? true;

    final ColorScheme colors = Theme.of(context).colorScheme;
    final int percent = (progress * 100).round();

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'TODAY\'S SCREEN TIME',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.sensors_rounded, size: 12, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: minutes),
          duration: const Duration(milliseconds: 1000),
          builder: (BuildContext context, int value, Widget? child) {
            return Text(
              _formatMinutes(value),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Tracked today across your apps',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onPrimaryContainer.withValues(alpha: 0.8),
              ),
        ),
      ],
    );

    final Widget dial = SizedBox(
      height: 140,
      width: 140,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double val, Widget? child) {
              return SizedBox(
                height: 130,
                width: 130,
                child: CircularProgressIndicator(
                  value: val,
                  strokeWidth: 11,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.onPrimaryContainer.withValues(alpha: 0.15),
                  color: colors.primary,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 1000),
                builder: (BuildContext context, int val, Widget? child) {
                  return Text(
                    '$val%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                  );
                },
              ),
              Text(
                'used',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      children: <Widget>[
        if (!hasPermission) ...<Widget>[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.security_rounded, color: colors.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Usage Access Required',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onErrorContainer,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enable Usage Access in Settings to detect exact live screen time.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onErrorContainer.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    await ref.read(usageStatsServiceProvider).requestUsagePermission();
                    ref.invalidate(todayLiveUsageProvider);
                  },
                  child: const Text('Grant'),
                ),
              ],
            ),
          ),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: colors.primaryContainer,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isWide
              ? Row(children: <Widget>[Expanded(child: content), dial])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    content,
                    const SizedBox(height: 20),
                    Align(alignment: Alignment.center, child: dial),
                  ],
                ),
        ),
      ],
    );
  }

  static String _formatMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}
