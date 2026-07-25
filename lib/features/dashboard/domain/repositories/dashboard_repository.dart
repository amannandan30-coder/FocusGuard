import '../entities/dashboard_metrics_entity.dart';
import '../entities/recent_activity_entity.dart';

abstract class DashboardRepository {
  /// Stream of user dashboard metrics from Firestore `users/{userId}`.
  Stream<DashboardMetricsEntity> watchDashboardMetrics(String userId);

  /// Stream of recent activities from `users/{userId}/activities` ordered newest first.
  Stream<List<RecentActivityEntity>> watchRecentActivities(String userId);

  /// Toggle focus session active status in Firestore.
  Future<void> setFocusActive(String userId, bool active);

  /// Log a new activity entry to `users/{userId}/activities`.
  Future<void> logActivity(String userId, RecentActivityEntity activity);
}
