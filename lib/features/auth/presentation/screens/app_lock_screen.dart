import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/security_service.dart';
import '../../../app_selection/data/device_app_service.dart';

final appUnlockedProvider = StateProvider<bool>((ref) => false);

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pinInput = '';
  bool _isError = false;
  bool _biometricsEnabled = false;
  String _appTitle = 'FocusGuard';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSecuritySettings();
    });
  }

  Future<void> _checkSecuritySettings() async {
    final SecurityService secService = ref.read(securityServiceProvider);
    final DeviceAppService appService = const DeviceAppService();

    final bool bioEnabled = await secService.isBiometricsEnabled();
    final String activeAlias = await appService.getActiveAppDisguise();

    String title = 'FocusGuard';
    if (activeAlias == 'CalculatorAlias') title = 'Calculator';
    if (activeAlias == 'NotesAlias') title = 'Notes';
    if (activeAlias == 'CalendarAlias') title = 'Calendar';
    if (activeAlias == 'ClockAlias') title = 'Clock';

    if (mounted) {
      setState(() {
        _biometricsEnabled = bioEnabled;
        _appTitle = title;
      });
    }

    if (bioEnabled) {
      await _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final SecurityService secService = ref.read(securityServiceProvider);
    final bool success = await secService.authenticateBiometric();
    if (success && mounted) {
      await HapticFeedback.mediumImpact();
      widget.onSuccess();
    }
  }

  Future<void> _handleKeyPress(String key) async {
    if (_pinInput.length >= 4) return;

    await HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      _pinInput += key;
    });

    if (_pinInput.length == 4) {
      final SecurityService secService = ref.read(securityServiceProvider);
      final bool isValid = await secService.verifyPin(_pinInput);
      if (isValid) {
        await HapticFeedback.mediumImpact();
        widget.onSuccess();
      } else {
        await HapticFeedback.vibrate();
        setState(() {
          _isError = true;
          _pinInput = '';
        });
      }
    }
  }

  Future<void> _handleBackspace() async {
    if (_pinInput.isNotEmpty) {
      await HapticFeedback.lightImpact();
      setState(() {
        _isError = false;
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Lock Icon Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 42,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _appTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isError ? 'Incorrect PIN. Try again.' : 'Enter your 4-digit PIN to unlock',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _isError ? colors.error : colors.onSurfaceVariant,
                        fontWeight: _isError ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                const SizedBox(height: 36),

                // 4-Dot PIN Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(4, (int index) {
                    final bool isFilled = index < _pinInput.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? (_isError ? colors.error : colors.primary)
                            : Colors.transparent,
                        border: Border.all(
                          color: _isError ? colors.error : colors.primary,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),

                // 3x4 Numeric Keypad
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    for (int i = 1; i <= 9; i++) _buildKeyButton('$i', colors),
                    if (_biometricsEnabled)
                      IconButton(
                        onPressed: _triggerBiometricAuth,
                        icon: Icon(Icons.fingerprint_rounded, size: 36, color: colors.primary),
                      )
                    else
                      const SizedBox.shrink(),
                    _buildKeyButton('0', colors),
                    IconButton(
                      onPressed: _handleBackspace,
                      icon: Icon(Icons.backspace_outlined, size: 26, color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(String text, ColorScheme colors) {
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _handleKeyPress(text),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
