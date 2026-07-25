class RecentActivityEntity {
  const RecentActivityEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
  });

  factory RecentActivityEntity.fromMap(String id, Map<String, dynamic>? data) {
    return RecentActivityEntity(
      id: id,
      title: data?['title'] as String? ?? 'Activity Logged',
      subtitle: data?['subtitle'] as String? ?? '',
      timestamp: (data?['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      type: data?['type'] as String? ?? 'info',
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String type;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp,
      'type': type,
    };
  }
}
