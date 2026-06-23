import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // User cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Sign-In Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
