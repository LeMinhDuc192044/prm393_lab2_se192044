import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_models.dart';
import '../services/firestore_service.dart';

abstract class UserSubcollectionRepository {
  UserSubcollectionRepository(this.uid, [FirestoreService? service])
      : service = service ?? FirestoreService.instance;

  final String uid;
  final FirestoreService service;

  CollectionReference<Map<String, dynamic>> get reference;

  Future<void> save(String id, Map<String, dynamic> data) => reference.doc(id).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

  Future<void> delete(String id) => reference.doc(id).delete();

  Stream<List<FirestoreItem>> watch() => reference.snapshots().map(
        (snapshot) => snapshot.docs.map(FirestoreItem.fromSnapshot).toList(),
      );
}

class UserRepository {
  UserRepository(this.uid, [this.service = FirestoreService.instance]);
  final String uid;
  final FirestoreService service;

  Future<UserProfile?> getProfile() async {
    final snapshot = await service.getUser(uid);
    return snapshot.exists ? UserProfile.fromSnapshot(snapshot) : null;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      service.user(uid).snapshots();

  Future<void> saveProfile(Map<String, dynamic> data) => service.user(uid).set({
        ...data,
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> deleteAccountData() async {
    final batch = service.batch();
    batch.delete(service.user(uid));
    await batch.commit();
  }
}

class BookmarkRepository extends UserSubcollectionRepository {
  BookmarkRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'bookmarks');
}

class FavoriteRepository extends UserSubcollectionRepository {
  FavoriteRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'favorite_journals');
}

class CollectionRepository extends UserSubcollectionRepository {
  CollectionRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'collections');
}

class CollectionItemRepository extends UserSubcollectionRepository {
  CollectionItemRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'collection_items');
}

class SearchRepository extends UserSubcollectionRepository {
  SearchRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'search_history');

  Query<Map<String, dynamic>> recent({int limit = 20}) =>
      reference.orderBy('searchedAt', descending: true).limit(limit);
}

class SettingsRepository extends UserSubcollectionRepository {
  SettingsRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'settings');
}

class NotificationRepository {
  NotificationRepository(this.uid, [this.service = FirestoreService.instance]);
  final String uid;
  final FirestoreService service;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActive() => service
      .collection('notifications')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots();
}

class FeedbackRepository {
  FeedbackRepository(this.uid, [this.service = FirestoreService.instance]);
  final String uid;
  final FirestoreService service;

  Future<DocumentReference<Map<String, dynamic>>> create(Map<String, dynamic> data) =>
      service.collection('feedback').add({...data, 'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
}

class ReportRepository {
  ReportRepository(this.uid, [this.service = FirestoreService.instance]);
  final String uid;
  final FirestoreService service;

  Future<DocumentReference<Map<String, dynamic>>> create(Map<String, dynamic> data) =>
      service.collection('reports').add({...data, 'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
}

class ActivityRepository extends UserSubcollectionRepository {
  ActivityRepository(super.uid, [super.service]);
  @override
  CollectionReference<Map<String, dynamic>> get reference =>
      service.userCollection(uid, 'activity_logs');
}
