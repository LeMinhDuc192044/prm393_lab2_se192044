import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    this.createdAt,
    this.lastLogin,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String provider;
  final Timestamp? createdAt;
  final Timestamp? lastLogin;

  Map<String, dynamic> toMap({bool includeCreatedAt = true, bool includeDefaults = false}) {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoUrl,
      'provider': provider,
      if (includeDefaults) ...{
        'role': 'USER',
        'status': 'ACTIVE',
        'favoriteCount': 0,
        'bookmarkCount': 0,
        'searchCount': 0,
      },
      if (includeCreatedAt) 'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
