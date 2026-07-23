import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() =>
      _firestore.collection('users').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFeedback() =>
      _firestore.collection('feedback').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReports() =>
      _firestore.collection('reports').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications() =>
      _firestore.collection('notifications').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserCollection(String uid, String name) =>
      _firestore.collection('users').doc(uid).collection(name).snapshots();

  Future<void> updateUserRole(String uid, String role) =>
      _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateUserStatus(String uid, String status) =>
      _firestore.collection('users').doc(uid).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateFeedbackStatus(String id, String status) =>
      _firestore.collection('feedback').doc(id).update({'status': status});

  Future<void> deleteFeedback(String id) =>
      _firestore.collection('feedback').doc(id).delete();

  Future<void> updateReportStatus(String id, String status) =>
      _firestore.collection('reports').doc(id).update({'status': status});

  Future<void> createNotification(Map<String, dynamic> data) =>
      _firestore.collection('notifications').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateNotification(String id, Map<String, dynamic> data) =>
      _firestore.collection('notifications').doc(id).update(data);

  Future<void> deleteNotification(String id) =>
      _firestore.collection('notifications').doc(id).delete();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConfig() =>
      _firestore.collection('app_config').doc('main').snapshots();

  Future<void> updateConfig(Map<String, dynamic> data) =>
      _firestore.collection('app_config').doc('main').set(data, SetOptions(merge: true));
}
