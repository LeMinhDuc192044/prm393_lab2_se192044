import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_sign_in_service.dart';

class AuthRepository {
  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

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
