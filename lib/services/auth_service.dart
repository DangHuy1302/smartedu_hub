import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create Firestore user document
    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      fullName: fullName,
      studyPoints: 0,
      totalBookings: 0,
      status: 'offline',
      isPomodoroActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userService.saveUser(user);

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optionally sync user data from Firestore
    final firestoreUser = await _userService.getUser(credential.user!.uid);
    if (firestoreUser == null) {
      // If no firestore user exists, create one based on auth profile
      final user = UserModel(
        uid: credential.user!.uid,
        email: credential.user!.email ?? email,
        fullName: credential.user!.displayName ?? '',
        studyPoints: 0,
        totalBookings: 0,
        status: 'offline',
        isPomodoroActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userService.saveUser(user);
    }

    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
