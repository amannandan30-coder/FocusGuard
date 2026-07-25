import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfileModel.fromUser(AppUser user, {DateTime? createdAt}) {
    final DateTime now = DateTime.now();
    return UserProfileModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
