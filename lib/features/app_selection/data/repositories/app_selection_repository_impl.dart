import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_entity.dart';
import '../../domain/repositories/app_selection_repository.dart';
import '../device_app_service.dart';

class AppSelectionRepositoryImpl implements AppSelectionRepository {
  AppSelectionRepositoryImpl({
    required DeviceAppService deviceAppService,
    required FirebaseFirestore firestore,
    SharedPreferences? sharedPreferences,
  })  : _deviceAppService = deviceAppService,
        _firestore = firestore,
        _prefs = sharedPreferences;

  final DeviceAppService _deviceAppService;
  final FirebaseFirestore _firestore;
  SharedPreferences? _prefs;

  static const String _keyLocalSelectedApps = 'fg_selected_apps_set';
  static const String _keyPendingSync = 'fg_pending_firestore_sync';

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<List<AppEntity>> getInstalledApps() async {
    return _deviceAppService.getSupportedInstalledApps();
  }

  @override
  Future<Set<String>> getLocalSelectedApps() async {
    final SharedPreferences prefs = await _getPrefs;
    final List<String>? localList = prefs.getStringList(_keyLocalSelectedApps);
    if (localList != null) {
      return localList.toSet();
    }

    // Fallback to native SharedPreferences via DeviceAppService
    final Set<String> nativeSelected = await _deviceAppService.getSelectedApps();
    if (nativeSelected.isNotEmpty) {
      await prefs.setStringList(_keyLocalSelectedApps, nativeSelected.toList());
    }
    return nativeSelected;
  }

  @override
  Future<void> saveSelectedApps({
    required String userId,
    required Set<String> selectedPackageIds,
    required List<AppEntity> allApps,
  }) async {
    final SharedPreferences prefs = await _getPrefs;

    // 1. Save locally immediately (Offline First)
    final List<String> packageList = selectedPackageIds.toList(growable: false);
    await prefs.setStringList(_keyLocalSelectedApps, packageList);
    await _deviceAppService.saveSelectedApps(selectedPackageIds);
    await prefs.setBool(_keyPendingSync, true);

    // 2. Attempt sync to Firestore in background
    try {
      await _syncToFirestore(userId, selectedPackageIds, allApps);
      await prefs.setBool(_keyPendingSync, false);
    } catch (_) {
      // Offline or network error: pending sync flag remains true
    }
  }

  @override
  Future<bool> syncPendingSelections(String userId) async {
    final SharedPreferences prefs = await _getPrefs;
    final bool hasPending = prefs.getBool(_keyPendingSync) ?? false;
    if (!hasPending) return true;

    final Set<String> selectedPackageIds = (prefs.getStringList(_keyLocalSelectedApps) ?? <String>[]).toSet();
    final List<AppEntity> installedApps = await getInstalledApps();

    try {
      await _syncToFirestore(userId, selectedPackageIds, installedApps);
      await prefs.setBool(_keyPendingSync, false);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasPendingSync() async {
    final SharedPreferences prefs = await _getPrefs;
    return prefs.getBool(_keyPendingSync) ?? false;
  }

  @override
  Stream<Set<String>> watchRemoteSelectedApps(String userId) {
    if (userId.isEmpty) return Stream<Set<String>>.value(<String>{});

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection('users').doc(userId).collection('selected_apps');

    return collection.snapshots().asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
      final Set<String> remoteSelected = <String>{};
      for (final DocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        final Map<String, dynamic>? data = doc.data();
        if (data != null && data['isSelected'] == true) {
          remoteSelected.add(doc.id);
        }
      }

      // Sync to local preferences if snapshot is not empty
      if (snapshot.docs.isNotEmpty) {
        final SharedPreferences prefs = await _getPrefs;
        final bool isPending = prefs.getBool(_keyPendingSync) ?? false;
        // Don't overwrite local un-synced user changes
        if (!isPending) {
          await prefs.setStringList(_keyLocalSelectedApps, remoteSelected.toList());
          await _deviceAppService.saveSelectedApps(remoteSelected);
        }
      }

      return remoteSelected;
    });
  }

  Future<void> _syncToFirestore(
    String userId,
    Set<String> selectedPackageIds,
    List<AppEntity> allApps,
  ) async {
    if (userId.isEmpty) return;

    final WriteBatch batch = _firestore.batch();
    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection('users').doc(userId).collection('selected_apps');

    final Map<String, AppEntity> appMap = <String, AppEntity>{
      for (final AppEntity app in allApps) app.packageId: app,
    };

    for (final AppEntity app in allApps) {
      final DocumentReference<Map<String, dynamic>> docRef = collection.doc(app.packageId);
      final bool isSelected = selectedPackageIds.contains(app.packageId);
      batch.set(
        docRef,
        <String, dynamic>{
          'appName': app.appName,
          'packageName': app.packageId,
          'isSelected': isSelected,
          'selectedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // For selected apps not in allApps list (e.g. legacy or uninstalled apps still selected)
    for (final String packageId in selectedPackageIds) {
      if (!appMap.containsKey(packageId)) {
        final DocumentReference<Map<String, dynamic>> docRef = collection.doc(packageId);
        batch.set(
          docRef,
          <String, dynamic>{
            'appName': packageId,
            'packageName': packageId,
            'isSelected': true,
            'selectedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    // Also update legacy profile field for backwards compatibility if needed
    final DocumentReference<Map<String, dynamic>> profileRef = _firestore.collection('users').doc(userId);
    batch.set(
      profileRef,
      <String, dynamic>{
        'selectedControlledApps': selectedPackageIds.toList(growable: false),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
