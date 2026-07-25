import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About FocusGuard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: <Widget>[
          // Header Card
          Card(
            elevation: 0,
            color: colors.primaryContainer.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.shield_outlined, size: 40, color: colors.onPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FocusGuard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create space for what matters.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Version 0.1.0+1',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Developer Info Card
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primary,
                    child: Text(
                      'AN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'DEVELOPER & CREATOR',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aman Nandan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Founder & Lead Developer',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Why FocusGuard Was Created Card
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.lightbulb_outline_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Why FocusGuard Was Created',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In today\'s hyper-connected world, short-form video algorithms (Shorts & Reels), endless scrolling, and digital noise constantly fragment our attention span—leading to lost time and reduced productivity.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'FocusGuard was crafted to empower you to reclaim control over your time. Rather than restricting technology completely, FocusGuard acts as a smart personal guardian that builds healthy digital habits and provides a quiet, focused environment for deep work.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Core Pillars
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Core Pillars',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildPillarTile(
                    context,
                    icon: Icons.shield_rounded,
                    title: 'Distraction Shielding',
                    description: 'Blocks addictive feeds (Shorts & Reels) without disabling essential apps.',
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  _buildPillarTile(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'Mindful Analytics',
                    description: 'Track screen time and app launches to build intentional daily habits.',
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  _buildPillarTile(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy & Stealth Mode',
                    description: 'Disguise app identity & lock settings with PIN & Biometrics.',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Footer Note
          Center(
            child: Text(
              'Crafted with passion by Aman Nandan for deep focus.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPillarTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 16,
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
