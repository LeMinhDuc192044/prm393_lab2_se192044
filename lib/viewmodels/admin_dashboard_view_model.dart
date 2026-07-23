import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../repositories/admin_repository.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  AdminDashboardViewModel({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;
  bool loading = false;
  String? errorMessage;
  String? successMessage;

  Stream<QuerySnapshot<Map<String, dynamic>>> get users => _repository.watchUsers();
  Stream<QuerySnapshot<Map<String, dynamic>>> get feedback => _repository.watchFeedback();
  Stream<QuerySnapshot<Map<String, dynamic>>> get reports => _repository.watchReports();
  Stream<QuerySnapshot<Map<String, dynamic>>> get notifications => _repository.watchNotifications();

  Future<void> updateRole(String uid, String role) => _run(() => _repository.updateUserRole(uid, role));
  Future<void> updateStatus(String uid, String status) => _run(() => _repository.updateUserStatus(uid, status));
  Future<void> updateFeedback(String id, String status) => _run(() => _repository.updateFeedbackStatus(id, status));
  Future<void> updateReport(String id, String status) => _run(() => _repository.updateReportStatus(id, status));
  Future<void> deleteFeedback(String id) => _run(() => _repository.deleteFeedback(id));

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      await action();
      successMessage = 'Changes saved.';
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
