import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const String _desktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
  );

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      await _googleSignIn.initialize(
        clientId: _desktopClientId.isEmpty ? null : _desktopClientId,
        serverClientId: _webClientId.isEmpty ? null : _webClientId,
      );
    } else if (kIsWeb) {
      await _googleSignIn.initialize(
        clientId: _webClientId.isEmpty ? null : _webClientId,
      );
    } else {
      await _googleSignIn.initialize(
        serverClientId: _webClientId.isEmpty ? null : _webClientId,
      );
    }
    _initialized = true;
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveUserProfile(userCredential.user, 'password');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: email sign-in failed code=${e.code}');
      throw Exception(_friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService: email sign-in unexpected error: $e');
      throw Exception('Email sign-in failed: $e');
    }
  }

  Future<User?> createUserWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveUserProfile(userCredential.user, 'password');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: email registration failed code=${e.code}');
      throw Exception(_friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService: email registration unexpected error: $e');
      throw Exception('Account registration failed: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final userCredential = await _firebaseAuth.signInWithPopup(
          GoogleAuthProvider(),
        );
        await _saveUserProfile(userCredential.user, 'google.com');
        return userCredential.user;
      }

      if (_isWindows) {
        throw Exception('Google Sign-In is not supported on Windows.');
      }

      await _ensureInitialized();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google did not return an ID token. Check GOOGLE_WEB_CLIENT_ID, '
          'Firebase Google provider, and Android SHA-1/SHA-256 settings.',
        );
      }

      return signInWithGoogleIdToken(googleAuth.idToken);
    } on GoogleSignInException catch (e) {
      debugPrint(
        'AuthService: GoogleSignInException code=${e.code} desc=${e.description}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw Exception('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException code=${e.code}');
      throw Exception(_friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService: unexpected Google sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e.code));
    }
  }

  Future<User?> signInWithGoogleIdToken(String? idToken) async {
    if (idToken == null) {
      throw Exception(
        'Google did not return an ID token. Check the Web OAuth Client ID '
        'and the Firebase Google provider configuration.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    await _saveUserProfile(userCredential.user, 'google.com');
    debugPrint(
      'AuthService: Firebase Google sign-in OK, uid=${userCredential.user?.uid}',
    );
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb && !_isWindows) {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    }
  }

  Future<void> _saveUserProfile(User? user, String provider) async {
    if (user == null) return;

    final reference = _firestore.collection('users').doc(user.uid);
    final existing = await reference.get();
    final profile = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      provider: provider,
    );
    await reference.set(
      profile.toMap(includeCreatedAt: !existing.exists),
      SetOptions(merge: true),
    );
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return 'Sign-in failed ($code). Please try again.';
    }
  }
}
