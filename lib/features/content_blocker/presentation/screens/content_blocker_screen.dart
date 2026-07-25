import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/content_blocker_service.dart';
import '../providers/content_blocker_providers.dart';

class ContentBlockerScreen extends ConsumerWidget {
  const ContentBlockerScreen({super.key});

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ContentBlockerConfig> asyncState = ref.watch(contentBlockerProvider);
    final ContentBlockerNotifier notifier = ref.read(contentBlockerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorts & Reels Blocker', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: () => notifier.loadConfig(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading blocker config: $error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => notifier.loadConfig(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (ContentBlockerConfig config) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Hero Blocked Stats Card
                  _BlockedStatsCard(count: config.blockedCountToday),
                  const SizedBox(height: 20),

                  // 2. Permission Status Card
                  if (_isAndroid && !config.isAccessibilityGranted)
                    _PermissionRequiredCard(onGrantPressed: notifier.openSettings)
                  else
                    _PermissionActiveCard(onManagePressed: notifier.openSettings),

                  const SizedBox(height: 24),

                  // 3. Toggles Header
                  Text(
                    'Distraction Shields',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Automatically detect and close addicting short video feeds in real-time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // 4. YouTube Shorts Toggle
                  _BlockerToggleCard(
                    title: 'Block YouTube Shorts',
                    subtitle: 'Exits YouTube Shorts player back to standard video player or feed.',
                    icon: Icons.play_circle_fill_rounded,
                    iconColor: const Color(0xFFFF0000),
                    value: config.blockYouTubeShorts,
                    onChanged: notifier.toggleYouTubeShorts,
                  ),
                  const SizedBox(height: 12),

                  // 5. Instagram Reels Toggle
                  _BlockerToggleCard(
                    title: 'Block Instagram Reels',
                    subtitle: 'Exits Instagram Reels viewer automatically.',
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFFE4405F),
                    value: config.blockInstagramReels,
                    onChanged: notifier.toggleInstagramReels,
                  ),
                  const SizedBox(height: 24),

                  // 6. Action Selector Section
                  Text(
                    'Blocking Action',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose what FocusGuard does when a Short or Reel is opened.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ActionSelectorCard(
                    selectedAction: config.blockingAction,
                    onActionSelected: notifier.updateBlockingAction,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BlockedStatsCard extends StatelessWidget {
  const _BlockedStatsCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Shorts & Reels Blocked Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'distractions stopped',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionRequiredCard extends StatelessWidget {
  const _PermissionRequiredCard({required this.onGrantPressed});

  final VoidCallback onGrantPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Accessibility Service Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'FocusGuard needs Accessibility Service permission to detect when Shorts or Reels are opened in third-party apps.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGrantPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.settings_applications_rounded),
                label: const Text('Enable Accessibility Service', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionActiveCard extends StatelessWidget {
  const _PermissionActiveCard({required this.onManagePressed});

  final VoidCallback onManagePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Accessibility Service Active',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Real-time protection is running smoothly.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onManagePressed,
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockerToggleCard extends StatelessWidget {
  const _BlockerToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: value ? theme.colorScheme.primary.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionSelectorCard extends StatelessWidget {
  const _ActionSelectorCard({
    required this.selectedAction,
    required this.onActionSelected,
  });

  final String selectedAction;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isBack = selectedAction == 'go_back';
    final bool isHome = selectedAction == 'go_home';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: Icon(
              isBack ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isBack ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            title: const Text('Press Back Button (Recommended)', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Exits the Short/Reel viewer and returns you to regular feed or video.'),
            onTap: () => onActionSelected('go_back'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              isHome ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isHome ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            title: const Text('Go to Home Screen', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Immediately returns your device to the home screen when a Short/Reel opens.'),
            onTap: () => onActionSelected('go_home'),
          ),
        ],
      ),
    );
  }
}
