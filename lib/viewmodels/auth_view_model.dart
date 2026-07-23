import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authRepository.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(String uid) =>
      _authRepository.watchUserProfile(uid);

  Future<void> ensureUserProfile(User user) =>
      _authRepository.ensureUserProfile(user);
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      () => _authRepository.signInWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<User?> login({required String email, required String password}) =>
      signInWithEmailPassword(email: email, password: password);

  Future<User?> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      () => _authRepository.createUserWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<User?> register({required String email, required String password}) =>
      createUserWithEmailPassword(email: email, password: password);

  Future<User?> signInWithGoogle() {
    return _runAuthAction(_authRepository.signInWithGoogle);
  }

  Future<User?> loginWithGoogle() => signInWithGoogle();

  Future<User?> signInWithGoogleIdToken(String? idToken) {
    return _runAuthAction(
      () => _authRepository.signInWithGoogleIdToken(idToken),
    );
  }

  Future<void> resetPassword(String email) async {
    await _runAuthAction(() async {
      await _authRepository.resetPassword(email);
      return null;
    });
  }

  Future<void> forgotPassword(String email) => resetPassword(email);

  Future<void> signOut() async {
    await _runAuthAction(() async {
      await _authRepository.signOut();
      return null;
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> _runAuthAction<T>(Future<T?> Function() action) async {
    if (_isLoading) return null;

    _setLoading(true);
    _errorMessage = null;

    try {
      return await action();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
