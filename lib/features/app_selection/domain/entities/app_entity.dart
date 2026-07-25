import 'dart:typed_data';

class AppEntity {
  AppEntity({
    required this.packageId,
    String? appName,
    String? name,
    required this.icon,
    this.isSelected = false,
    this.selectedAt,
  }) : appName = appName ?? name ?? '';

  final String packageId;
  final String appName;
  String get name => appName;
  final Uint8List? icon;
  final bool isSelected;
  final DateTime? selectedAt;

  AppEntity copyWith({
    String? packageId,
    String? appName,
    String? name,
    Uint8List? icon,
    bool? isSelected,
    DateTime? selectedAt,
  }) {
    return AppEntity(
      packageId: packageId ?? this.packageId,
      appName: appName ?? name ?? this.appName,
      icon: icon ?? this.icon,
      isSelected: isSelected ?? this.isSelected,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'appName': appName,
      'packageName': packageId,
      'isSelected': isSelected,
      'selectedAt': selectedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

// Alias for compatibility
typedef ControllableApp = AppEntity;
