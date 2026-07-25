import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_selection/presentation/screens/app_selection_screen.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import 'focus_session_sheet.dart';
import 'streak_card.dart';

class QuickStatsGrid extends ConsumerWidget {
  const QuickStatsGrid({super.key});

  void _showUnlockInsightsSheet(BuildContext context, int unlockCount) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String statusLabel = unlockCount <= 25
        ? 'Mindful Pickups 🟢'
        : unlockCount <= 55
            ? 'Frequent Checking 🟡'
            : 'High Pickup Frequency 🔴';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Icon(Icons.phonelink_lock_rounded, color: colors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Phone Unlock Insights',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            statusLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Total Unlocks Today:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '$unlockCount times',
                        style: TextStyle(fontWeight: FontWeight.w800, color: colors.primary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tips to Reduce Pickups:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const BulletTip(text: 'Keep your phone face down or out of reach during work.'),
                const BulletTip(text: 'Disable non-essential app notification badges.'),
                const BulletTip(text: 'Start a Focus Session to block distracting app launches.'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final unlockCount = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.unlockCount ?? 0),
    );
    final focusSessionsCount = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.focusSessionsCount ?? 0),
    );
    final appsControlledCount = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.appsControlledCount ?? 0),
    );
    final timeSavedMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.timeSavedMinutes ?? 0),
    );
    final goalMinutes = ref.watch(dailyGoalMinutesProvider);

    final ColorScheme colors = Theme.of(context).colorScheme;

    final List<_QuickStatItem> items = <_QuickStatItem>[
      _QuickStatItem(
        title: 'UNLOCK COUNT',
        value: '$unlockCount times',
        icon: Icons.phonelink_lock_rounded,
        color: colors.primary,
        onTap: () => _showUnlockInsightsSheet(context, unlockCount),
      ),
      _QuickStatItem(
        title: 'FOCUS SESSIONS',
        value: '$focusSessionsCount completed',
        icon: Icons.play_circle_outline_rounded,
        color: Colors.teal,
        onTap: () => FocusSessionSheet.show(context),
      ),
      _QuickStatItem(
        title: 'APPS CONTROLLED',
        value: '$appsControlledCount active',
        icon: Icons.apps_rounded,
        color: colors.secondary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AppSelectionScreen()),
          );
        },
      ),
      _QuickStatItem(
        title: 'TIME SAVED',
        value: '${_formatMinutes(timeSavedMinutes)} today',
        icon: Icons.savings_outlined,
        color: Colors.orange,
        onTap: () {
          const StreakCard().showGoalPicker(context, ref, goalMinutes);
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final _QuickStatItem item = items[index];
        return Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(item.icon, size: 20, color: item.color),
                      const Spacer(),
                      Container(
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class BulletTip extends StatelessWidget {
  const BulletTip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _QuickStatItem {
  const _QuickStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
