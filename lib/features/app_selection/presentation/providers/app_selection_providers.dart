import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/device_app_service.dart';
import '../../data/repositories/app_selection_repository_impl.dart';
import '../../domain/entities/app_entity.dart';
import '../../domain/repositories/app_selection_repository.dart';

final Provider<DeviceAppService> deviceAppServiceProvider =
    Provider<DeviceAppService>((Ref ref) => const DeviceAppService());

final Provider<AppSelectionRepository> appSelectionRepositoryProvider =
    Provider<AppSelectionRepository>((Ref ref) {
  return AppSelectionRepositoryImpl(
    deviceAppService: ref.watch(deviceAppServiceProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final FutureProvider<List<AppEntity>> installedAppsProvider =
    FutureProvider<List<AppEntity>>((Ref ref) async {
  return ref.watch(appSelectionRepositoryProvider).getInstalledApps();
});

// Alias for legacy code compatibility
final FutureProvider<List<AppEntity>> installedSupportedAppsProvider = installedAppsProvider;

final FutureProvider<Set<String>> localSelectedAppsProvider =
    FutureProvider<Set<String>>((Ref ref) {
  return ref.watch(appSelectionRepositoryProvider).getLocalSelectedApps();
});

class SavedAppSelection {
  const SavedAppSelection({required this.packageIds, required this.isConfigured});

  final Set<String> packageIds;
  final bool isConfigured;
}

final StreamProviderFamily<SavedAppSelection, String> savedAppSelectionProvider =
    StreamProvider.family<SavedAppSelection, String>((Ref ref, String userId) {
  return ref
      .watch(appSelectionRepositoryProvider)
      .watchRemoteSelectedApps(userId)
      .map((Set<String> packageIds) => SavedAppSelection(packageIds: packageIds, isConfigured: true));
});

class AppSelectionController extends StateNotifier<AsyncValue<void>> {
  AppSelectionController(this._ref, this._userId) : super(const AsyncData<void>(null));

  final Ref _ref;
  final String _userId;

  Future<void> save(Set<String> packageIds) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final List<AppEntity> apps = await _ref.read(installedAppsProvider.future);
      await _ref.read(appSelectionRepositoryProvider).saveSelectedApps(
            userId: _userId,
            selectedPackageIds: packageIds,
            allApps: apps,
          );
    });
  }
}

final StateNotifierProviderFamily<AppSelectionController, AsyncValue<void>, String>
    appSelectionControllerProvider = StateNotifierProvider.family<AppSelectionController, AsyncValue<void>, String>(
  (Ref ref, String userId) => AppSelectionController(ref, userId),
);

final StateProvider<String> searchQueryProvider = StateProvider<String>((Ref ref) => '');

final Provider<List<AppEntity>> filteredAppsProvider = Provider<List<AppEntity>>((Ref ref) {
  final AsyncValue<List<AppEntity>> appsAsync = ref.watch(installedAppsProvider);
  final String query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return appsAsync.when(
    data: (List<AppEntity> apps) {
      if (query.isEmpty) {
        return apps;
      }
      return apps.where((AppEntity app) {
        return app.appName.toLowerCase().contains(query) ||
            app.packageId.toLowerCase().contains(query);
      }).toList(growable: false);
    },
    loading: () => const <AppEntity>[],
    error: (_, __) => const <AppEntity>[],
  );
});

class AppSelectionState {
  const AppSelectionState({
    required this.selectedPackageIds,
    this.isInitialLoading = true,
    this.isSaving = false,
    this.hasPendingSync = false,
    this.errorMessage,
  });

  final Set<String> selectedPackageIds;
  final bool isInitialLoading;
  final bool isSaving;
  final bool hasPendingSync;
  final String? errorMessage;

  AppSelectionState copyWith({
    Set<String>? selectedPackageIds,
    bool? isInitialLoading,
    bool? isSaving,
    bool? hasPendingSync,
    String? errorMessage,
  }) {
    return AppSelectionState(
      selectedPackageIds: selectedPackageIds ?? this.selectedPackageIds,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isSaving: isSaving ?? this.isSaving,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      errorMessage: errorMessage,
    );
  }
}

class AppSelectionNotifier extends StateNotifier<AppSelectionState> {
  AppSelectionNotifier(this._repository, this._userId)
      : super(const AppSelectionState(selectedPackageIds: <String>{})) {
    _init();
  }

  final AppSelectionRepository _repository;
  final String _userId;

  Future<void> _init() async {
    // 1. Read local selections immediately (Offline First)
    final Set<String> localSelected = await _repository.getLocalSelectedApps();
    final bool pending = await _repository.hasPendingSync();
    state = state.copyWith(
      selectedPackageIds: localSelected,
      isInitialLoading: false,
      hasPendingSync: pending,
    );

    // 2. Trigger background sync if there were pending changes
    if (pending && _userId.isNotEmpty) {
      await retryPendingSync(<AppEntity>[]);
    }

    // 3. Listen to remote changes for real-time cross-device sync
    if (_userId.isNotEmpty) {
      _repository.watchRemoteSelectedApps(_userId).listen((Set<String> remoteSet) async {
        if (!mounted) {
          return;
        }
        final bool isPending = await _repository.hasPendingSync();
        if (!isPending) {
          state = state.copyWith(selectedPackageIds: remoteSet, hasPendingSync: false);
        }
      });
    }
  }

  Future<void> toggleApp(String packageId, List<AppEntity> allApps) async {
    final Set<String> current = Set<String>.from(state.selectedPackageIds);
    if (current.contains(packageId)) {
      current.remove(packageId);
    } else {
      current.add(packageId);
    }
    await _updateSelection(current, allApps);
  }

  Future<void> selectAll(List<AppEntity> apps) async {
    final Set<String> current = Set<String>.from(state.selectedPackageIds);
    for (final AppEntity app in apps) {
      current.add(app.packageId);
    }
    await _updateSelection(current, apps);
  }

  Future<void> clearAll(List<AppEntity> apps) async {
    final Set<String> current = Set<String>.from(state.selectedPackageIds);
    for (final AppEntity app in apps) {
      current.remove(app.packageId);
    }
    await _updateSelection(current, apps);
  }

  Future<void> retryPendingSync(List<AppEntity> allApps) async {
    if (_userId.isEmpty) {
      return;
    }
    state = state.copyWith(isSaving: true);
    final bool success = await _repository.syncPendingSelections(_userId);
    if (mounted) {
      state = state.copyWith(isSaving: false, hasPendingSync: !success);
    }
  }

  Future<void> _updateSelection(Set<String> nextSelected, List<AppEntity> allApps) async {
    // Immediate UI update & local save (Offline First)
    state = state.copyWith(selectedPackageIds: nextSelected, isSaving: true, errorMessage: null);

    try {
      await _repository.saveSelectedApps(
        userId: _userId,
        selectedPackageIds: nextSelected,
        allApps: allApps,
      );
      final bool pending = await _repository.hasPendingSync();
      if (mounted) {
        state = state.copyWith(isSaving: false, hasPendingSync: pending);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSaving: false, hasPendingSync: true);
      }
    }
  }
}

final StateNotifierProviderFamily<AppSelectionNotifier, AppSelectionState, String>
    appSelectionNotifierProvider = StateNotifierProvider.family<AppSelectionNotifier, AppSelectionState, String>(
  (Ref ref, String userId) {
    return AppSelectionNotifier(
      ref.watch(appSelectionRepositoryProvider),
      userId,
    );
  },
);
