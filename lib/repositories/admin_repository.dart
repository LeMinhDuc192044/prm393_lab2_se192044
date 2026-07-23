import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_service.dart';

class AdminRepository {
  AdminRepository({AdminService? service}) : _service = service ?? AdminService();
  final AdminService _service;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() => _service.watchUsers();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchFeedback() => _service.watchFeedback();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchReports() => _service.watchReports();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications() => _service.watchNotifications();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserCollection(String uid, String name) => _service.watchUserCollection(uid, name);
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConfig() => _service.watchConfig();
  Future<void> updateUserRole(String uid, String role) => _service.updateUserRole(uid, role);
  Future<void> updateUserStatus(String uid, String status) => _service.updateUserStatus(uid, status);
  Future<void> updateFeedbackStatus(String id, String status) => _service.updateFeedbackStatus(id, status);
  Future<void> deleteFeedback(String id) => _service.deleteFeedback(id);
  Future<void> updateReportStatus(String id, String status) => _service.updateReportStatus(id, status);
  Future<void> createNotification(Map<String, dynamic> data) => _service.createNotification(data);
  Future<void> updateNotification(String id, Map<String, dynamic> data) => _service.updateNotification(id, data);
  Future<void> deleteNotification(String id) => _service.deleteNotification(id);
  Future<void> updateConfig(Map<String, dynamic> data) => _service.updateConfig(data);
}
