import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class ProductivityScoreCard extends ConsumerWidget {
  const ProductivityScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final score = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.productivityScore ?? 85),
    );

    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color scoreColor = _scoreColor(score, colors);
    final String category = _scoreCategory(score);

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
                    color: scoreColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_graph_rounded, color: scoreColor, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'PRODUCTIVITY SCORE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 1000),
                  builder: (BuildContext context, int val, Widget? child) {
                    return Text(
                      '$val',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: scoreColor,
                          ),
                    );
                  },
                ),
                Text(
                  ' / 100',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _scoreSubtitle(score),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: (score / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double val, Widget? child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: val,
                    minHeight: 7,
                    color: scoreColor,
                    backgroundColor: scoreColor.withValues(alpha: 0.14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(int score, ColorScheme colors) {
    if (score >= 90) return Colors.teal;
    if (score >= 75) return colors.primary;
    if (score >= 50) return Colors.amber.shade700;
    if (score >= 35) return Colors.deepOrange;
    return colors.error;
  }

  static String _scoreCategory(int score) {
    if (score >= 90) return 'Super Focused 🚀';
    if (score >= 75) return 'Productive 👍';
    if (score >= 50) return 'Moderate ⚡';
    if (score >= 35) return 'High Distraction ⚠️';
    return 'Limit Overused 🚨';
  }

  static String _scoreSubtitle(int score) {
    if (score >= 90) return 'Top-tier digital wellbeing momentum!';
    if (score >= 75) return 'Great focus balance maintained today!';
    if (score >= 50) return 'Fair usage. Keep an eye on screen limit.';
    if (score >= 35) return 'Limit exceeded. Step back from screens.';
    return 'Heavy screen overuse detected today!';
  }
}
