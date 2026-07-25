import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';

class MotivationQuoteCard extends ConsumerWidget {
  const MotivationQuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String quote = ref.watch(dailyQuoteProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.tertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.format_quote_rounded, color: colors.tertiary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TODAY\'S REMINDER',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colors.onTertiaryContainer,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  quote,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: colors.onTertiaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
