import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// google_sign_in v7 requires an explicit async initialize() call
  /// before any sign-in operation. Safe to call multiple times.
  ///
  /// serverClientId is the Web client ID from Firebase/Google Cloud
  /// Console (NOT the Android client ID). Required for Android — without
  /// it, Google won't issue an ID token and sign-in fails silently.
  static const String _serverClientId =
      '703569163237-3qt6ss56idppqr9gk1erhve6upceroa8.apps.googleusercontent.com';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Currently signed-in user, or null if signed out.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes — use this to react to sign-in/sign-out.
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
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: email registration failed code=${e.code}');
      throw Exception(_friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService: email registration unexpected error: $e');
      throw Exception('Account registration failed: $e');
    }
  }

  /// Signs in with Google. Returns the signed-in [User], or null if the
  /// user cancelled the Google account picker.
  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      debugPrint('AuthService: initialized OK');

      // 1. Trigger Google authentication (v7: authenticate() replaces signIn()).
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      debugPrint('AuthService: authenticate() returned ${googleUser.email}');

      // 2. Get the ID token needed for Firebase.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      debugPrint(
          'AuthService: idToken is ${googleAuth.idToken == null ? "NULL" : "present"}');

      if (googleAuth.idToken == null) {
        throw Exception(
            'Google did not return an ID token. This usually means the '
            'serverClientId is missing or incorrect in initialize().');
      }

      // 3. Create a Firebase credential.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential.
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      debugPrint("Firebase sign-in successful");
      debugPrint("UID: ${userCredential.user?.uid}");
      debugPrint("Email: ${userCredential.user?.email}");

      debugPrint(
          'AuthService: Firebase sign-in OK, uid=${userCredential.user?.uid}');

      return userCredential.user;
    } on GoogleSignInException catch (e) {
      debugPrint(
          'AuthService: GoogleSignInException code=${e.code} desc=${e.description}');
      // User cancelled the picker, or another Google-side issue.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw Exception('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException code=${e.code}');
      throw Exception(_friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('AuthService: unexpected error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Signs out of both Firebase and Google.
  Future<void> signOut() async {
    await _ensureInitialized();
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
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
      case 'wrong-password':
        return 'Invalid email or password.';
      default:
        return 'Sign-in failed ($code). Please try again.';
    }
  }
}
