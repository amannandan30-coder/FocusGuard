import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return const SecurityService();
});

class SecurityService {
  const SecurityService();

  static const MethodChannel _channel = MethodChannel('com.focusguard.app/security');

  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyAppLockPin = 'app_lock_pin';
  static const String _keyBiometricsEnabled = 'app_lock_biometrics_enabled';

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isAppLockEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppLockEnabled) ?? false;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, enabled);
  }

  Future<String?> getPin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppLockPin);
  }

  Future<void> setPin(String pin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLockPin, pin);
  }

  Future<bool> isBiometricsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricsEnabled) ?? false;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricsEnabled, enabled);
  }

  Future<bool> isBiometricHardwareAvailable() async {
    if (!isAndroid) return false;
    try {
      final bool? available = await _channel.invokeMethod<bool>('isBiometricAvailable');
      return available ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    if (!isAndroid) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>('authenticateBiometric');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> verifyPin(String inputPin) async {
    final String? storedPin = await getPin();
    return storedPin != null && storedPin == inputPin;
  }
}
