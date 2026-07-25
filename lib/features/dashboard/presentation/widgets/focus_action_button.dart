import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/focus_session_providers.dart';
import 'focus_session_sheet.dart';

class FocusActionButton extends ConsumerWidget {
  const FocusActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FocusSessionState sessionState = ref.watch(focusSessionProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final bool isFocusActive = sessionState.isActive;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton.icon(
          onPressed: () {
            FocusSessionSheet.show(context);
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(62),
            backgroundColor: isFocusActive ? colors.secondaryContainer : colors.primary,
            foregroundColor: isFocusActive ? colors.onSecondaryContainer : colors.onPrimary,
            elevation: isFocusActive ? 2 : 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          icon: Icon(
            isFocusActive ? Icons.timer_rounded : Icons.play_circle_fill_rounded,
            size: 26,
          ),
          label: Text(
            isFocusActive
                ? 'Focus Session Active (${sessionState.formattedRemaining})'
                : 'Start Focus Session',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}
