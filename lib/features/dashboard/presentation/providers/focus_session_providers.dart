import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/content_blocker_service.dart';
import '../../../content_blocker/presentation/providers/content_blocker_providers.dart';

class FocusSessionState {
  const FocusSessionState({
    required this.isActive,
    required this.targetMinutes,
    required this.remainingSeconds,
    required this.completedSessionsToday,
  });

  final bool isActive;
  final int targetMinutes;
  final int remainingSeconds;
  final int completedSessionsToday;

  String get formattedRemaining {
    final int minutes = remainingSeconds ~/ 60;
    final int seconds = remainingSeconds % 60;
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  double get progress {
    final int totalSeconds = targetMinutes * 60;
    if (totalSeconds == 0) return 0.0;
    final double elapsed = (totalSeconds - remainingSeconds).toDouble();
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  FocusSessionState copyWith({
    bool? isActive,
    int? targetMinutes,
    int? remainingSeconds,
    int? completedSessionsToday,
  }) {
    return FocusSessionState(
      isActive: isActive ?? this.isActive,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
    );
  }
}

class FocusSessionNotifier extends StateNotifier<FocusSessionState> with WidgetsBindingObserver {
  FocusSessionNotifier(this._blockerService)
      : super(const FocusSessionState(
          isActive: false,
          targetMinutes: 25,
          remainingSeconds: 25 * 60,
          completedSessionsToday: 0,
        )) {
    WidgetsBinding.instance.addObserver(this);
    _loadAndSyncState();
  }

  final ContentBlockerService _blockerService;
  Timer? _timer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAndSyncState();
    }
  }

  Future<void> _loadAndSyncState() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final String savedDate = prefs.getString('focus_sessions_date') ?? '';
      final int completed = savedDate == todayStr ? (prefs.getInt('focus_sessions_completed') ?? 0) : 0;

      final bool isActive = prefs.getBool('focus_session_is_active') ?? false;
      final int startTimeMs = prefs.getInt('focus_session_start_time_ms') ?? 0;
      final int targetMinutes = prefs.getInt('focus_session_target_minutes') ?? 25;

      if (isActive && startTimeMs > 0) {
        final int nowMs = DateTime.now().millisecondsSinceEpoch;
        final int elapsedSeconds = (nowMs - startTimeMs) ~/ 1000;
        final int totalSeconds = targetMinutes * 60;
        final int remaining = totalSeconds - elapsedSeconds;

        if (remaining > 0) {
          state = state.copyWith(
            isActive: true,
            targetMinutes: targetMinutes,
            remainingSeconds: remaining,
            completedSessionsToday: completed,
          );
          _startInternalTimer();
          await _blockerService.setFocusSessionActive(true);
          return;
        } else {
          // Session expired while app was closed or in background
          await _completeSession(targetMinutes: targetMinutes, passedPrefs: prefs);
          return;
        }
      }

      state = state.copyWith(
        isActive: false,
        completedSessionsToday: completed,
        remainingSeconds: state.targetMinutes * 60,
      );
    } catch (_) {}
  }

  Future<void> startSession(int durationMinutes) async {
    _timer?.cancel();

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int totalSeconds = durationMinutes * 60;

    state = state.copyWith(
      isActive: true,
      targetMinutes: durationMinutes,
      remainingSeconds: totalSeconds,
    );

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('focus_session_is_active', true);
      await prefs.setInt('focus_session_start_time_ms', nowMs);
      await prefs.setInt('focus_session_target_minutes', durationMinutes);
    } catch (_) {}

    await _blockerService.setFocusSessionActive(true);
    _startInternalTimer();
  }

  void _startInternalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _completeSession(targetMinutes: state.targetMinutes);
      }
    });
  }

  Future<void> stopSession() async {
    _timer?.cancel();
    _timer = null;

    state = state.copyWith(
      isActive: false,
      remainingSeconds: state.targetMinutes * 60,
    );

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('focus_session_is_active', false);
      await prefs.remove('focus_session_start_time_ms');
    } catch (_) {}

    await _blockerService.setFocusSessionActive(false);
  }

  Future<void> _completeSession({int? targetMinutes, SharedPreferences? passedPrefs}) async {
    _timer?.cancel();
    _timer = null;

    final int currentTarget = targetMinutes ?? state.targetMinutes;
    final int newCount = state.completedSessionsToday + 1;

    state = state.copyWith(
      isActive: false,
      completedSessionsToday: newCount,
      remainingSeconds: currentTarget * 60,
    );

    try {
      final SharedPreferences prefs = passedPrefs ?? await SharedPreferences.getInstance();
      final String todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setBool('focus_session_is_active', false);
      await prefs.remove('focus_session_start_time_ms');
      await prefs.setString('focus_sessions_date', todayStr);
      await prefs.setInt('focus_sessions_completed', newCount);
    } catch (_) {}

    await _blockerService.setFocusSessionActive(false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final focusSessionProvider =
    StateNotifierProvider<FocusSessionNotifier, FocusSessionState>((ref) {
  return FocusSessionNotifier(ref.watch(contentBlockerServiceProvider));
});
