import '../entities/app_entity.dart';

abstract class AppSelectionRepository {
  /// Fetches installed launchable applications from device.
  Future<List<AppEntity>> getInstalledApps();

  /// Reads selected application package IDs from local storage (SharedPreferences).
  Future<Set<String>> getLocalSelectedApps();

  /// Saves app selection state locally immediately and queues/triggers background Firestore sync.
  Future<void> saveSelectedApps({
    required String userId,
    required Set<String> selectedPackageIds,
    required List<AppEntity> allApps,
  });

  /// Syncs any queued offline pending selections to Firestore.
  Future<bool> syncPendingSelections(String userId);

  /// Checks if there are pending offline changes waiting to be synced.
  Future<bool> hasPendingSync();

  /// Listens to remote Firestore selection updates for cross-device syncing.
  Stream<Set<String>> watchRemoteSelectedApps(String userId);
}
