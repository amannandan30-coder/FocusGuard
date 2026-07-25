import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/entities/recent_activity_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<DashboardMetricsEntity> watchDashboardMetrics(String userId) {
    if (userId.isEmpty) {
      return Stream<DashboardMetricsEntity>.value(DashboardMetricsEntity.fromMap(null));
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) =>
            DashboardMetricsEntity.fromMap(snapshot.data()));
  }

  @override
  Stream<List<RecentActivityEntity>> watchRecentActivities(String userId) {
    if (userId.isEmpty) {
      return Stream<List<RecentActivityEntity>>.value(const <RecentActivityEntity>[]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.docs.isEmpty) {
        return const <RecentActivityEntity>[];
      }
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              RecentActivityEntity.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    });
  }

  @override
  Future<void> setFocusActive(String userId, bool active) async {
    if (userId.isEmpty) return;

    final DocumentReference<Map<String, dynamic>> userDoc = _firestore.collection('users').doc(userId);

    await userDoc.set(<String, dynamic>{
      'isFocusActive': active,
      active ? 'focusStartedAt' : 'focusEndedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also log to activities subcollection
    final String activityTitle = active ? 'Started Focus Session' : 'Ended Focus Session';
    final String activitySub = active ? 'Deep focus mode active' : 'Session complete';

    await userDoc.collection('activities').add(<String, dynamic>{
      'title': activityTitle,
      'subtitle': activitySub,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'session',
    });
  }

  @override
  Future<void> logActivity(String userId, RecentActivityEntity activity) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .add(<String, dynamic>{
      'title': activity.title,
      'subtitle': activity.subtitle,
      'timestamp': FieldValue.serverTimestamp(),
      'type': activity.type,
    });
  }
}
