import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_sign_in_service.dart';

class AuthRepository {
  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(String uid) =>
      _authService.watchUserProfile(uid);

  Future<void> ensureUserProfile(User user) =>
      _authService.ensureUserProfile(user);

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<User?> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authService.createUserWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<User?> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  Future<User?> signInWithGoogleIdToken(String? idToken) {
    return _authService.signInWithGoogleIdToken(idToken);
  }

  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  Future<void> signOut() {
    return _authService.signOut();
  }
}
