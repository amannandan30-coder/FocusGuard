import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ContentBlockerConfig {
  const ContentBlockerConfig({
    required this.isAccessibilityGranted,
    required this.blockYouTubeShorts,
    required this.blockInstagramReels,
    required this.blockingAction,
    required this.blockedCountToday,
  });

  factory ContentBlockerConfig.fromMap(Map<dynamic, dynamic> map) {
    return ContentBlockerConfig(
      isAccessibilityGranted: map['isAccessibilityGranted'] == true,
      blockYouTubeShorts: map['blockYouTubeShorts'] == true,
      blockInstagramReels: map['blockInstagramReels'] == true,
      blockingAction: (map['blockingAction'] as String?) ?? 'go_back',
      blockedCountToday: (map['blockedCountToday'] as num?)?.toInt() ?? 0,
    );
  }

  final bool isAccessibilityGranted;
  final bool blockYouTubeShorts;
  final bool blockInstagramReels;
  final String blockingAction; // 'go_back' or 'go_home'
  final int blockedCountToday;

  ContentBlockerConfig copyWith({
    bool? isAccessibilityGranted,
    bool? blockYouTubeShorts,
    bool? blockInstagramReels,
    String? blockingAction,
    int? blockedCountToday,
  }) {
    return ContentBlockerConfig(
      isAccessibilityGranted: isAccessibilityGranted ?? this.isAccessibilityGranted,
      blockYouTubeShorts: blockYouTubeShorts ?? this.blockYouTubeShorts,
      blockInstagramReels: blockInstagramReels ?? this.blockInstagramReels,
      blockingAction: blockingAction ?? this.blockingAction,
      blockedCountToday: blockedCountToday ?? this.blockedCountToday,
    );
  }
}

class ContentBlockerService {
  const ContentBlockerService();

  static const MethodChannel _channel = MethodChannel('com.focusguard.app/accessibility');

  Future<bool> isAccessibilityGranted() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? result = await _channel.invokeMethod<bool>('isAccessibilityGranted');
        return result ?? false;
      } on PlatformException catch (e) {
        debugPrint('Accessibility permission check error: $e');
        return false;
      }
    }
    return true; // Mock for non-Android platforms
  }

  Future<void> openAccessibilitySettings() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('openAccessibilitySettings');
      } on PlatformException catch (e) {
        debugPrint('Open accessibility settings error: $e');
      }
    }
  }

  Future<ContentBlockerConfig> getBlockerConfig() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final Map<dynamic, dynamic>? res =
            await _channel.invokeMethod<Map<dynamic, dynamic>>('getBlockerConfig');
        if (res != null) {
          return ContentBlockerConfig.fromMap(res);
        }
      } on PlatformException catch (e) {
        debugPrint('Error getting blocker config: $e');
      }
    }

    return const ContentBlockerConfig(
      isAccessibilityGranted: true,
      blockYouTubeShorts: true,
      blockInstagramReels: true,
      blockingAction: 'go_back',
      blockedCountToday: 12,
    );
  }

  Future<bool> saveBlockerConfig({
    required bool blockYouTubeShorts,
    required bool blockInstagramReels,
    required String blockingAction,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? result = await _channel.invokeMethod<bool>(
          'saveBlockerConfig',
          <String, dynamic>{
            'blockYouTubeShorts': blockYouTubeShorts,
            'blockInstagramReels': blockInstagramReels,
            'blockingAction': blockingAction,
          },
        );
        return result ?? false;
      } on PlatformException catch (e) {
        debugPrint('Save blocker config error: $e');
        return false;
      }
    }
    return true;
  }

  Future<bool> setFocusSessionActive(bool active) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? result = await _channel.invokeMethod<bool>(
          'setFocusSessionActive',
          <String, dynamic>{'active': active},
        );
        return result ?? false;
      } on PlatformException catch (e) {
        debugPrint('Set focus session active error: $e');
        return false;
      }
    }
    return true;
  }
}
