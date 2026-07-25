import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/usage_stats_service.dart';
import '../providers/dashboard_providers.dart';

class WeeklyDetailScreen extends ConsumerStatefulWidget {
  const WeeklyDetailScreen({super.key, this.initialDayIndex = 0});

  final int initialDayIndex; // 0 = Mon, 1 = Tue ... 6 = Sun

  @override
  ConsumerState<WeeklyDetailScreen> createState() => _WeeklyDetailScreenState();
}

class _WeeklyDetailScreenState extends ConsumerState<WeeklyDetailScreen> {
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.initialDayIndex.clamp(0, 6);
  }

  // Returns list of 7 DateTime objects representing Monday through Sunday of current week (at 12:00 AM)
  List<DateTime> get _weekDays {
    final DateTime now = DateTime.now();
    final int currentWeekday = now.weekday; // 1 = Mon ... 7 = Sun
    final DateTime monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));

    return List<DateTime>.generate(7, (int index) => monday.add(Duration(days: index)));
  }

  static const List<String> _dayNames = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _monthNames = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatFullDate(DateTime dt) {
    return '${_dayNames[dt.weekday - 1]}, ${_monthNames[dt.month - 1]} ${dt.day}';
  }

  String _formatMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<DateTime> weekDays = _weekDays;
    final DateTime selectedDate = weekDays[_selectedDayIndex];
    final int selectedDayStartMs = selectedDate.millisecondsSinceEpoch;

    final AsyncValue<PeriodUsageResult> dayUsageAsync = ref.watch(specificDayUsageProvider(selectedDayStartMs));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly & Daily Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          // Day Selector Tabs Bar (Mon - Sun)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List<Widget>.generate(7, (int index) {
                final bool isSelected = _selectedDayIndex == index;
                final DateTime date = weekDays[index];
                final bool isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : isToday
                                  ? colors.primaryContainer.withValues(alpha: 0.5)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: <Widget>[
                            Text(
                              _dayNames[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? colors.onPrimary
                                    : isToday
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.onPrimary.withValues(alpha: 0.8)
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Selected Day Usage Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(specificDayUsageProvider(selectedDayStartMs));
              },
              child: dayUsageAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object err, _) => Center(
                  child: Text('Failed to load usage: $err'),
                ),
                data: (PeriodUsageResult result) {
                  final List<AppUsageStats> apps = result.appsUsage;
                  final int totalMinutes = result.totalScreenTimeMinutes;
                  final int totalSessions = result.totalSessionsCount;
                  final int maxMs = apps.isEmpty ? 1 : apps.first.totalTimeInForegroundMs;

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: <Widget>[
                      // Day Summary Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _formatFullDate(selectedDate).toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'SCREEN TIME',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onPrimaryContainer.withValues(alpha: 0.6),
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatMinutes(totalMinutes),
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: colors.onPrimaryContainer,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: colors.onPrimaryContainer.withValues(alpha: 0.2),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'APP LAUNCHES',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onPrimaryContainer.withValues(alpha: 0.6),
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$totalSessions opens',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: colors.onPrimaryContainer,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Applications Used (${apps.length} active)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (apps.isEmpty)
                        Card(
                          elevation: 0,
                          color: colors.surfaceContainerLow,
                          child: const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('No application usage recorded for this date.'),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: apps.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final AppUsageStats app = apps[index];
                            final double ratio = maxMs == 0 ? 0 : (app.totalTimeInForegroundMs / maxMs).clamp(0.0, 1.0);

                            return Card(
                              elevation: 0,
                              color: colors.surfaceContainerLow,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        if (app.icon != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.memory(
                                              app.icon!,
                                              width: 42,
                                              height: 42,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 21,
                                            backgroundColor: colors.primaryContainer,
                                            child: Text(
                                              app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.onPrimaryContainer),
                                            ),
                                          ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                app.appName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: <Widget>[
                                                  Text(
                                                    'Opened ${app.sessionCount} time${app.sessionCount == 1 ? '' : 's'}',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: colors.onSurfaceVariant,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('•', style: TextStyle(color: colors.outline)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      app.formattedLastUsed,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: colors.onSurfaceVariant,
                                                          ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          app.formattedDuration,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        backgroundColor: colors.surfaceContainerHighest,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
