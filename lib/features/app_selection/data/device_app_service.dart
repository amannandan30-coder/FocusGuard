import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/app_entity.dart';

class DeviceAppService {
  const DeviceAppService();

  static const MethodChannel _channel = MethodChannel('com.focusguard.app/app_selection');

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<List<AppEntity>> getSupportedInstalledApps() async {
    if (!isAndroid) {
      return const <AppEntity>[];
    }
    try {
      final List<Object?>? result = await _channel.invokeListMethod<Object?>('getSupportedInstalledApps');
      return result
              ?.whereType<Map<Object?, Object?>>()
              .map(_toAppEntity)
              .toList(growable: false) ??
          const <AppEntity>[];
    } on PlatformException catch (_) {
      return const <AppEntity>[];
    }
  }

  Future<Set<String>> getSelectedApps() async {
    if (!isAndroid) {
      return <String>{};
    }
    try {
      final List<Object?>? result = await _channel.invokeListMethod<Object?>('getSelectedApps');
      return result?.whereType<String>().toSet() ?? <String>{};
    } on PlatformException catch (_) {
      return <String>{};
    }
  }

  Future<void> saveSelectedApps(Set<String> packageIds) async {
    if (!isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('saveSelectedApps', packageIds.toList(growable: false));
    } on PlatformException catch (_) {
      // Ignore or log error
    }
  }

  Future<bool> changeAppIconAndName(String aliasName) async {
    if (!isAndroid) {
      return false;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'changeAppIconAndName',
        <String, dynamic>{'aliasName': aliasName},
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<String> getActiveAppDisguise() async {
    if (!isAndroid) {
      return 'DefaultAlias';
    }
    try {
      final String? result = await _channel.invokeMethod<String>('getActiveAppDisguise');
      return result ?? 'DefaultAlias';
    } on PlatformException catch (_) {
      return 'DefaultAlias';
    }
  }

  Future<Uint8List?> pickCustomIconImage() async {
    if (!isAndroid) {
      return null;
    }
    try {
      final Uint8List? bytes = await _channel.invokeMethod<Uint8List>('pickCustomIconImage');
      return bytes;
    } on PlatformException catch (_) {
      return null;
    }
  }

  AppEntity _toAppEntity(Map<Object?, Object?> value) {
    return AppEntity(
      packageId: value['packageId']! as String,
      appName: value['name']! as String,
      icon: value['icon'] as Uint8List?,
    );
  }
}
