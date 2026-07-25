import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_shimmer_skeleton.dart';
import '../widgets/focus_action_button.dart';
import '../widgets/motivation_quote_card.dart';
import '../widgets/productivity_score_card.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/screen_time_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/weekly_progress_chart.dart';
import '../widgets/welcome_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final String userId = user?.id ?? '';

    if (userId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AsyncValue<DashboardMetrics> metricsAsync = ref.watch(dashboardMetricsProvider(userId));
    final DashboardMetrics? metrics = metricsAsync.valueOrNull;

    if (metrics == null && metricsAsync.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: DashboardShimmerView(),
        ),
      );
    }

    if (metrics == null && metricsAsync.hasError) {
      return Scaffold(
        body: _DashboardErrorView(
          onRetry: () {
            ref.invalidate(todayLiveUsageProvider);
            ref.invalidate(dashboardMetricsProvider(userId));
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayLiveUsageProvider);
            ref.invalidate(dashboardMetricsProvider(userId));
            ref.invalidate(recentActivitiesStreamProvider(userId));
          },
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isWide = constraints.maxWidth >= 840;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // 1. Welcome Header
                        const WelcomeHeader(),
                        const SizedBox(height: 20),

                        // 2. Today's Screen Time Card (Hero)
                        ScreenTimeCard(isWide: isWide),
                        const SizedBox(height: 16),

                        // 2b. Start / End Focus Session Button
                        const FocusActionButton(),
                        const SizedBox(height: 16),

                        // 3. Weekly Progress Chart (Real Device History)
                        const WeeklyProgressChart(),
                        const SizedBox(height: 16),

                        // 4 & 5. Focus Streak Card & Productivity Score Card
                        if (isWide)
                          const Row(
                            children: <Widget>[
                              Expanded(child: StreakCard()),
                              SizedBox(width: 16),
                              Expanded(child: ProductivityScoreCard()),
                            ],
                          )
                        else ...<Widget>[
                          const StreakCard(),
                          const SizedBox(height: 16),
                          const ProductivityScoreCard(),
                        ],
                        const SizedBox(height: 16),

                        // 6. Daily Motivation Card
                        const MotivationQuoteCard(),
                        const SizedBox(height: 16),

                        // 7. Quick Statistics Grid (4 mini cards)
                        const QuickStatsGrid(),
                        const SizedBox(height: 20),

                        // 8. Recent Activity List Feed
                        const RecentActivityList(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  const _DashboardErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.wifi_off_rounded, size: 54, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Unable to load dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection or try again in a few moments.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
