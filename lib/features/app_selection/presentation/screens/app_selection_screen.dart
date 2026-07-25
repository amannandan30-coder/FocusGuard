import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/app_entity.dart';
import '../providers/app_selection_providers.dart';
import '../widgets/app_card_skeleton.dart';

class AppSelectionScreen extends ConsumerWidget {
  const AppSelectionScreen({super.key});

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final AsyncValue<List<AppEntity>> installedAppsAsync = ref.watch(installedAppsProvider);
    final List<AppEntity> filteredApps = ref.watch(filteredAppsProvider);
    final String searchQuery = ref.watch(searchQueryProvider);
    final AppSelectionState selectionState = ref.watch(appSelectionNotifierProvider(userId));
    final AppSelectionNotifier notifier = ref.read(appSelectionNotifierProvider(userId).notifier);

    final List<AppEntity> allInstalledApps = installedAppsAsync.valueOrNull ?? <AppEntity>[];
    final int selectedCount = selectionState.selectedPackageIds.length;
    final bool hasSelection = selectedCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Apps', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: <Widget>[
          if (selectionState.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Search Bar & Actions Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Choose apps to manage with FocusGuard.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    onChanged: (String value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search apps or package name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selection summary & Select All / Clear All toolbar
                  Row(
                    children: <Widget>[
                      Text(
                        '$selectedCount app${selectedCount == 1 ? '' : 's'} selected',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: selectionState.isSaving || allInstalledApps.isEmpty
                            ? null
                            : () => notifier.selectAll(allInstalledApps),
                        icon: const Icon(Icons.select_all_rounded, size: 18),
                        label: const Text('Select All'),
                      ),
                      TextButton.icon(
                        onPressed: selectionState.isSaving || selectionState.selectedPackageIds.isEmpty
                            ? null
                            : () => notifier.clearAll(allInstalledApps),
                        icon: const Icon(Icons.deselect_rounded, size: 18),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),

                  // Offline Pending Sync Notification Banner
                  if (selectionState.hasPendingSync) ...<Widget>[
                    const SizedBox(height: 6),
                    Material(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => notifier.retryPendingSync(allInstalledApps),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.wifi_off_rounded, size: 18, color: Theme.of(context).colorScheme.onTertiaryContainer),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Saved locally. Tap to retry Firestore sync.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              Icon(Icons.refresh_rounded, size: 18, color: Theme.of(context).colorScheme.onTertiaryContainer),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // App List Section
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(installedAppsProvider);
                },
                child: installedAppsAsync.when(
                  loading: () => const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: AppListSkeleton(count: 6),
                  ),
                  error: (Object error, StackTrace stackTrace) => _ErrorView(
                    onRetry: () => ref.invalidate(installedAppsProvider),
                  ),
                  data: (List<AppEntity> apps) {
                    if (!_isAndroid) {
                      return const _AndroidOnlyView();
                    }

                    if (apps.isEmpty) {
                      return const _NoAppsView();
                    }

                    if (filteredApps.isEmpty && searchQuery.isNotEmpty) {
                      return _NoSearchResultView(query: searchQuery);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filteredApps.length,
                      itemBuilder: (BuildContext context, int index) {
                        final AppEntity app = filteredApps[index];
                        final bool isSelected = selectionState.selectedPackageIds.contains(app.packageId);

                        return Card(
                          elevation: isSelected ? 2 : 0,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
                              : Theme.of(context).colorScheme.surfaceContainerLow,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            secondary: _AppIcon(iconBytes: app.icon),
                            title: Text(
                              app.appName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            subtitle: Text(
                              app.packageId,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            value: isSelected,
                            onChanged: (bool value) {
                              notifier.toggleApp(app.packageId, allInstalledApps);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Validation Footer
      bottomSheet: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!hasSelection) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select at least one application to continue.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: hasSelection
                        ? () {
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      hasSelection ? 'Continue' : 'Select an App to Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.iconBytes});

  final Uint8List? iconBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 48,
        width: 48,
        child: iconBytes == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.apps_rounded, color: Theme.of(context).colorScheme.primary),
              )
            : Image.memory(iconBytes!, fit: BoxFit.cover),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 54, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load installed apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'An error occurred while scanning your device for applications.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AndroidOnlyView extends StatelessWidget {
  const _AndroidOnlyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.phone_android_rounded, size: 54, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Android Only Feature',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'App monitoring and management is supported on Android devices.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAppsView extends StatelessWidget {
  const _NoAppsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.apps_outage_rounded, size: 54, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'No user applications found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No launchable third-party applications were detected on this device.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultView extends StatelessWidget {
  const _NoSearchResultView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No matching apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No apps found matching "$query".',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
