import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';
import '../models/user.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '681946323599-nscvoc269s7ejd6j5gthlt6qfn0r577s.apps.googleusercontent.com',
  );
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in flow
        return null;
      }

      // Obtain the auth details from the user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Ensure Firestore user document exists / is synced
      final user = userCredential.user;
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          studyPoints: 0,
          totalBookings: 0,
          status: 'offline',
          isPomodoroActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await UserService().saveUser(userModel);
      }

      return userCredential;
    } catch (e) {
      // Handle both Firebase and Google Sign-In errors uniformly
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

  /// Get Google Sign-In user
  Future<GoogleSignInAccount?> get signedInUser async {
    return await _googleSignIn.signInSilently();
  }

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
