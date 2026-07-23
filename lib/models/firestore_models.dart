import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({required this.uid, required this.data});

  final String uid;
  final Map<String, dynamic> data;

  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) =>
      UserProfile(uid: snapshot.id, data: snapshot.data() ?? const {});

  Map<String, dynamic> toMap() => {'uid': uid, ...data};
}

class FirestoreItem {
  const FirestoreItem({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  factory FirestoreItem.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      FirestoreItem(id: doc.id, data: doc.data());
}
