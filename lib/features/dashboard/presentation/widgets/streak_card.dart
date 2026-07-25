import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  void showGoalPicker(BuildContext context, WidgetRef ref, int currentGoal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final List<int> presets = <int>[60, 90, 120, 150, 180, 240, 300];
        int selectedHours = currentGoal ~/ 60;
        int selectedMinutes = currentGoal % 60;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set Daily Screen Time Goal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your focus streak increments for every consecutive day your screen time stays under this goal.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QUICK PRESETS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((int mins) {
                        final bool isSelected = mins == (selectedHours * 60 + selectedMinutes);
                        return ChoiceChip(
                          label: Text(_formatMinutes(mins)),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                selectedHours = mins ~/ 60;
                                selectedMinutes = mins % 60;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CUSTOM TIME GOAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hours',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedHours.clamp(0, 12),
                                isExpanded: true,
                                items: List<DropdownMenuItem<int>>.generate(13, (int i) {
                                  return DropdownMenuItem<int>(
                                    value: i,
                                    child: Text('$i hr${i == 1 ? "" : "s"}'),
                                  );
                                }),
                                onChanged: (int? val) {
                                  if (val != null) {
                                    setState(() {
                                      selectedHours = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: (selectedMinutes ~/ 5 * 5).clamp(0, 55),
                                isExpanded: true,
                                items: List<DropdownMenuItem<int>>.generate(12, (int i) {
                                  final int m = i * 5;
                                  return DropdownMenuItem<int>(
                                    value: m,
                                    child: Text('$m min${m == 1 ? "" : "s"}'),
                                  );
                                }),
                                onChanged: (int? val) {
                                  if (val != null) {
                                    setState(() {
                                      selectedMinutes = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Save Goal (${_formatMinutes(selectedHours * 60 + selectedMinutes)})'),
                        onPressed: () {
                          final int totalMins = (selectedHours * 60) + selectedMinutes;
                          if (totalMins > 0) {
                            ref.read(dailyGoalMinutesProvider.notifier).setGoal(totalMins);
                            ref.invalidate(todayLiveUsageProvider);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final currentStreak = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.currentStreak ?? 0),
    );
    final longestStreak = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.longestStreak ?? 0),
    );
    final weeklyStreak = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.weeklyStreak ?? 0),
    );
    final monthlyStreak = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.monthlyStreak ?? 0),
    );

    final todayMinutes = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.todayScreenMinutes ?? 0),
    );
    final goalMinutes = ref.watch(dailyGoalMinutesProvider);

    final ColorScheme colors = Theme.of(context).colorScheme;
    const Color flameColor = Colors.orange;

    final bool isUnderLimit = todayMinutes <= goalMinutes;
    final int percent = goalMinutes == 0 ? 0 : ((todayMinutes / goalMinutes) * 100).round();

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
                    color: flameColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: flameColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'FOCUS STREAK',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Text(
                            '$currentStreak ${currentStreak == 1 ? "Day" : "Days"}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(width: 6),
                          const Text('🔥', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Set daily goal limit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showGoalPicker(context, ref, goalMinutes),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showGoalPicker(context, ref, goalMinutes),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUnderLimit
                      ? colors.primaryContainer.withValues(alpha: 0.5)
                      : colors.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      isUnderLimit ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                      size: 16,
                      color: isUnderLimit ? colors.primary : colors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isUnderLimit
                            ? 'Today: ${_formatMinutes(todayMinutes)} / ${_formatMinutes(goalMinutes)} ($percent%) — Under limit! Tap to change.'
                            : 'Today: ${_formatMinutes(todayMinutes)} / ${_formatMinutes(goalMinutes)} ($percent%) — Limit exceeded. Tap to change.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isUnderLimit ? colors.onPrimaryContainer : colors.onErrorContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StreakStatTile(
                    label: 'BEST STREAK',
                    value: '$longestStreak d',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
                Container(height: 32, width: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
                Expanded(
                  child: _StreakStatTile(
                    label: 'THIS WEEK',
                    value: '$weeklyStreak d',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                Container(height: 32, width: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
                Expanded(
                  child: _StreakStatTile(
                    label: 'THIS MONTH',
                    value: '$monthlyStreak d',
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ],
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

class _StreakStatTile extends StatelessWidget {
  const _StreakStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
