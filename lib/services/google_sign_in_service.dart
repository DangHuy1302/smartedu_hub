import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';
import '../models/user.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _initialized = false;

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId:
          '681946323599-nscvoc269s7ejd6j5gthlt6qfn0r577s.apps.googleusercontent.com',
    );
    _initialized = true;
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes(<String>['openid', 'email', 'profile']);

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authorization?.accessToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      return userCredential;
    } catch (e) {
      debugPrint('Sign-In Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get Google Sign-In user
  Future<GoogleSignInAccount?> get signedInUser async {
    await _ensureInitialized();
    final Future<GoogleSignInAccount?>? result = GoogleSignIn.instance
        .attemptLightweightAuthentication();
    return result == null ? null : await result;
  }

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
