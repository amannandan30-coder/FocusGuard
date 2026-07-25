import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/security_service.dart';
import '../../../../core/services/usage_stats_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../app_selection/data/device_app_service.dart';
import '../../../app_selection/presentation/screens/app_selection_screen.dart';
import '../../../content_blocker/presentation/screens/content_blocker_screen.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../providers/auth_providers.dart';
import 'about_screen.dart';
import 'app_lock_screen.dart';

final appLockEnabledProvider = FutureProvider<bool>((ref) async {
  final securityService = ref.watch(securityServiceProvider);
  return securityService.isAppLockEnabled();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final ThemeMode mode = ref.watch(themeModeProvider);
    final int selectedIndex = ref.watch(bottomNavIndexProvider);
    final AsyncValue<bool> appLockEnabledAsync = ref.watch(appLockEnabledProvider);
    final bool isUnlocked = ref.watch(appUnlockedProvider);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (appLockEnabledAsync.valueOrNull == true && !isUnlocked) {
      return AppLockScreen(
        onSuccess: () => ref.read(appUnlockedProvider.notifier).state = true,
      );
    }

    final List<Widget> screens = <Widget>[
      const DashboardScreen(),
      const StatisticsTab(),
      const ContentBlockerScreen(),
      const _SettingsTab(),
      _ProfileTab(userName: user.displayName ?? 'FocusGuard User', userEmail: user.email ?? ''),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('FocusGuard', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'App selection',
            icon: const Icon(Icons.apps_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AppSelectionScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Blocker',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class StatisticsTab extends ConsumerStatefulWidget {
  const StatisticsTab({super.key});

  @override
  ConsumerState<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<StatisticsTab> {
  String _selectedPeriod = 'daily';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PeriodUsageResult> usageAsync = ref.watch(periodUsageProvider(_selectedPeriod));
    final ColorScheme colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(periodUsageProvider(_selectedPeriod));
      },
      child: usageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load usage statistics: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(periodUsageProvider(_selectedPeriod)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (PeriodUsageResult result) {
          if (!result.hasPermission) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.security_rounded, size: 54, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Usage Access Required',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To display exact app usage statistics, please grant Usage Access Permission in Android Settings.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () async {
                        await ref.read(usageStatsServiceProvider).requestUsagePermission();
                        ref.invalidate(periodUsageProvider(_selectedPeriod));
                      },
                      icon: const Icon(Icons.settings_suggest_rounded),
                      label: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<AppUsageStats> apps = result.appsUsage;
          final int totalMinutes = result.totalScreenTimeMinutes;
          final int totalSessions = result.totalSessionsCount;
          final int maxMs = apps.isEmpty ? 1 : apps.first.totalTimeInForegroundMs;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              // Header & Timeframe Segmented Control
              Text(
                'Usage Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'daily', label: Text('Today')),
                    ButtonSegment<String>(value: 'weekly', label: Text('Weekly')),
                    ButtonSegment<String>(value: 'monthly', label: Text('Monthly')),
                  ],
                  selected: <String>{_selectedPeriod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedPeriod = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'TOTAL SCREEN TIME',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 4),
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
                      height: 40,
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
                                  color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 4),
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
              ),
              const SizedBox(height: 20),

              Text(
                'Application Details (${apps.length} active)',
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
                      child: Text('No app usage recorded for this timeframe.'),
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
    );
  }

  static String _formatMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.apps_rounded),
                title: const Text('Managed Applications', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose apps FocusGuard monitors'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AppSelectionScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shield_rounded),
                title: const Text('Shorts & Reels Blocker', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Configure YouTube Shorts & Instagram Reels shields'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ContentBlockerScreen()),
                ),
              ),
              const Divider(height: 1),
              const _AppDisguiseTile(),
              const Divider(height: 1),
              const _AppLockTile(),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(mode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                value: mode == ThemeMode.dark,
                onChanged: (bool value) {
                  ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('About FocusGuard', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Created by Aman Nandan • App Vision & Info'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(userName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(userEmail, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AppDisguiseTile extends StatefulWidget {
  const _AppDisguiseTile();

  @override
  State<_AppDisguiseTile> createState() => _AppDisguiseTileState();
}

class _AppDisguiseTileState extends State<_AppDisguiseTile> {
  String _activeAlias = 'DefaultAlias';
  final DeviceAppService _service = const DeviceAppService();

  static const Map<String, Map<String, dynamic>> _disguises = <String, Map<String, dynamic>>{
    'DefaultAlias': <String, dynamic>{
      'label': 'FocusGuard',
      'icon': Icons.shield_rounded,
      'description': 'Default app icon and title',
    },
    'CalculatorAlias': <String, dynamic>{
      'label': 'Calculator',
      'icon': Icons.calculate_rounded,
      'description': 'Disguise as standard Calculator app',
    },
    'NotesAlias': <String, dynamic>{
      'label': 'Notes',
      'icon': Icons.edit_note_rounded,
      'description': 'Disguise as standard Notepad / Notes app',
    },
    'CalendarAlias': <String, dynamic>{
      'label': 'Calendar',
      'icon': Icons.calendar_month_rounded,
      'description': 'Disguise as standard Calendar app',
    },
    'ClockAlias': <String, dynamic>{
      'label': 'Clock',
      'icon': Icons.access_time_filled_rounded,
      'description': 'Disguise as standard Alarm / Clock app',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadDisguise();
  }

  Future<void> _loadDisguise() async {
    final String current = await _service.getActiveAppDisguise();
    if (mounted) {
      setState(() {
        _activeAlias = current;
      });
    }
  }

  Future<void> _showDisguiseDialog() async {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: <Widget>[
              Icon(Icons.visibility_off_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'App Disguise (Stealth Mode)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Hide FocusGuard on launcher by disguising its name and icon as a standard utility app:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ..._disguises.entries.map((MapEntry<String, Map<String, dynamic>> entry) {
                final String aliasKey = entry.key;
                final String label = entry.value['label'] as String;
                final IconData icon = entry.value['icon'] as IconData;
                final String desc = entry.value['description'] as String;
                final bool isSelected = _activeAlias == aliasKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(aliasKey),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primaryContainer.withValues(alpha: 0.6) : colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? colors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: isSelected ? colors.primary : colors.surfaceContainerHighest,
                            foregroundColor: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                            radius: 18,
                            child: Icon(icon, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(desc, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null && selected != _activeAlias) {
      final bool ok = await _service.changeAppIconAndName(selected);
      if (ok && mounted) {
        setState(() {
          _activeAlias = selected;
        });
        final String newLabel = _disguises[selected]?['label'] as String? ?? 'App';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App disguised as "$newLabel". Android launcher will update the logo & name shortly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentLabel = _disguises[_activeAlias]?['label'] as String? ?? 'FocusGuard';

    return ListTile(
      leading: const Icon(Icons.visibility_off_rounded),
      title: const Text('App Disguise (Stealth Mode)', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Current: $currentLabel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              currentLabel,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: _showDisguiseDialog,
    );
  }
}

class _AppLockTile extends ConsumerStatefulWidget {
  const _AppLockTile();

  @override
  ConsumerState<_AppLockTile> createState() => _AppLockTileState();
}

class _AppLockTileState extends ConsumerState<_AppLockTile> {
  bool _isLockEnabled = false;
  bool _isBioEnabled = false;
  String? _pin;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final SecurityService sec = ref.read(securityServiceProvider);
    final bool enabled = await sec.isAppLockEnabled();
    final bool bioEnabled = await sec.isBiometricsEnabled();
    final String? pin = await sec.getPin();
    if (mounted) {
      setState(() {
        _isLockEnabled = enabled;
        _isBioEnabled = bioEnabled;
        _pin = pin;
      });
    }
  }

  Future<void> _showLockConfigDialog() async {
    final SecurityService sec = ref.read(securityServiceProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextEditingController pinController = TextEditingController(text: _pin ?? '');

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: <Widget>[
                  Icon(Icons.lock_person_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  const Text('App Lock & Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('App Lock on Launch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text('Require PIN / Fingerprint when app opens', style: TextStyle(fontSize: 11)),
                      value: _isLockEnabled,
                      onChanged: (bool val) async {
                        if (val && (_pin == null || _pin!.length != 4)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please save a 4-digit PIN first.')),
                          );
                          return;
                        }
                        await sec.setAppLockEnabled(val);
                        ref.invalidate(appLockEnabledProvider);
                        setStateDialog(() => _isLockEnabled = val);
                        setState(() => _isLockEnabled = val);
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Set 4-Digit Security PIN', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter 4 digits',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_rounded),
                          onPressed: () async {
                            if (pinController.text.length == 4) {
                              await sec.setPin(pinController.text);
                              setStateDialog(() => _pin = pinController.text);
                              setState(() => _pin = pinController.text);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PIN saved successfully!')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PIN must be exactly 4 digits.')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fingerprint / Biometrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text('Unlock with Fingerprint or Face ID', style: TextStyle(fontSize: 11)),
                      value: _isBioEnabled,
                      onChanged: (bool val) async {
                        await sec.setBiometricsEnabled(val);
                        setStateDialog(() => _isBioEnabled = val);
                        setState(() => _isBioEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_outline_rounded),
      title: const Text('App Lock Security', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_isLockEnabled ? 'Enabled (PIN & Biometrics)' : 'Disabled'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: _showLockConfigDialog,
    );
  }
}
