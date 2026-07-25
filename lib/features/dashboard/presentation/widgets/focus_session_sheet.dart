import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/focus_session_providers.dart';

class FocusSessionSheet extends ConsumerStatefulWidget {
  const FocusSessionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const FocusSessionSheet(),
    );
  }

  @override
  ConsumerState<FocusSessionSheet> createState() => _FocusSessionSheetState();
}

class _FocusSessionSheetState extends ConsumerState<FocusSessionSheet> {
  int _selectedDuration = 25;
  bool _isCustom = false;

  static const List<int> _presetDurations = <int>[15, 25, 45, 60];

  Future<void> _showCustomDurationDialog() async {
    final TextEditingController controller = TextEditingController(text: '$_selectedDuration');
    final ColorScheme colors = Theme.of(context).colorScheme;

    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempVal = _selectedDuration;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: <Widget>[
              Icon(Icons.tune_rounded, color: colors.primary),
              const SizedBox(width: 10),
              const Text('Custom Duration', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Set session time in minutes (1 - 180 min):',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: tempVal > 1
                            ? () {
                                setDialogState(() {
                                  tempVal = (tempVal - 5).clamp(1, 180);
                                  controller.text = '$tempVal';
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            suffixText: 'm',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onChanged: (String val) {
                            final int? parsed = int.tryParse(val);
                            if (parsed != null && parsed >= 1 && parsed <= 180) {
                              setDialogState(() {
                                tempVal = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: tempVal < 180
                            ? () {
                                setDialogState(() {
                                  tempVal = (tempVal + 5).clamp(1, 180);
                                  controller.text = '$tempVal';
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick shortcut chips inside dialog
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: <int>[5, 10, 30, 90, 120].map((int shortcut) {
                      return ChoiceChip(
                        label: Text('${shortcut}m'),
                        selected: tempVal == shortcut,
                        onSelected: (_) {
                          setDialogState(() {
                            tempVal = shortcut;
                            controller.text = '$shortcut';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final int? finalMinutes = int.tryParse(controller.text);
                if (finalMinutes != null && finalMinutes >= 1 && finalMinutes <= 180) {
                  Navigator.of(context).pop(finalMinutes);
                } else {
                  Navigator.of(context).pop(tempVal);
                }
              },
              child: const Text('Set Duration'),
            ),
          ],
        );
      },
    );

    if (result != null && result >= 1 && result <= 180) {
      setState(() {
        _selectedDuration = result;
        _isCustom = !_presetDurations.contains(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final FocusSessionState sessionState = ref.watch(focusSessionProvider);
    final FocusSessionNotifier notifier = ref.read(focusSessionProvider.notifier);
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    final appsControlledCount = ref.watch(
      dashboardMetricsProvider(userId).select((AsyncValue<DashboardMetrics> m) => m.valueOrNull?.appsControlledCount ?? 0),
    );

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: <Widget>[
                  Icon(
                    sessionState.isActive ? Icons.shield_rounded : Icons.timer_outlined,
                    color: sessionState.isActive ? Colors.teal : colors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          sessionState.isActive ? 'Focus Session Active' : 'Start Focus Session',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          sessionState.isActive
                              ? 'Strict blocking enabled for $appsControlledCount managed app${appsControlledCount == 1 ? '' : 's'}'
                              : 'Select duration to start deep work session',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Animated Countdown Dial
              SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 170,
                      width: 170,
                      child: CircularProgressIndicator(
                        value: sessionState.isActive ? sessionState.progress : 1.0,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colors.surfaceContainerHighest,
                        color: sessionState.isActive ? Colors.teal : colors.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          sessionState.isActive
                              ? sessionState.formattedRemaining
                              : '$_selectedDuration:00',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 36,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sessionState.isActive ? 'REMAINING' : 'TARGET DURATION',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Duration Selection Chips (when not active)
              if (!sessionState.isActive) ...<Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ..._presetDurations.map((int duration) {
                        final bool isSelected = _selectedDuration == duration && !_isCustom;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              '${duration}m',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? colors.onPrimary : colors.onSurface,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: colors.primary,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDuration = duration;
                                  _isCustom = false;
                                });
                              }
                            },
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _isCustom ? colors.onPrimary : colors.primary,
                          ),
                          label: Text(
                            _isCustom ? 'Custom (${_selectedDuration}m)' : 'Custom',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isCustom ? colors.onPrimary : colors.primary,
                            ),
                          ),
                          selected: _isCustom,
                          selectedColor: colors.primary,
                          onSelected: (_) => _showCustomDurationDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Active App Shield Notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.shield_outlined, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'During active sessions, managed apps are automatically blocked when opened.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (sessionState.isActive) {
                      await notifier.stopSession();
                      if (context.mounted) Navigator.of(context).pop();
                    } else {
                      await notifier.startSession(_selectedDuration);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: sessionState.isActive ? colors.error : colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: Icon(sessionState.isActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(
                    sessionState.isActive ? 'End Session Early' : 'Start Focus Session (${_selectedDuration}m)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
