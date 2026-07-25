import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/recent_activity_entity.dart';
import '../providers/dashboard_providers.dart';

class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final AsyncValue<List<RecentActivityEntity>> activitiesAsync =
        ref.watch(recentActivitiesStreamProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              'Live Feed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        activitiesAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
          data: (List<RecentActivityEntity> activities) {
            if (activities.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activities logged yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final RecentActivityEntity item = activities[index];
                return _ActivityTile(activity: item);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final RecentActivityEntity activity;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final _ActivityStyle style = _getStyle(activity.type, colors);

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(style.icon, color: style.color, size: 20),
        ),
        title: Text(
          activity.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          activity.subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        trailing: Text(
          _timeAgo(activity.timestamp),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.outline,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  static _ActivityStyle _getStyle(String type, ColorScheme colors) {
    switch (type) {
      case 'session':
        return _ActivityStyle(icon: Icons.play_circle_fill_rounded, color: colors.primary);
      case 'goal':
        return _ActivityStyle(icon: Icons.emoji_events_rounded, color: Colors.teal);
      case 'block':
        return _ActivityStyle(icon: Icons.block_rounded, color: colors.error);
      case 'streak':
        return _ActivityStyle(icon: Icons.local_fire_department_rounded, color: Colors.orange);
      default:
        return _ActivityStyle(icon: Icons.info_outline_rounded, color: colors.secondary);
    }
  }

  static String _timeAgo(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ActivityStyle {
  const _ActivityStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}
