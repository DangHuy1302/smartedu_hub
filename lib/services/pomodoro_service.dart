import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PomodoroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> startPomodoro({required String uid}) async {
    await _firestore.collection('users').doc(uid).set({
      'isPomodoroActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Ends a session and awards study points (1 minute = 1 point).
  /// `initialSeconds` is the session configured length in seconds.
  Future<void> endPomodoro({
    required String uid,
    required int initialSeconds,
    required int secondsRemaining,
  }) async {
    final int secondsSpent = (initialSeconds - secondsRemaining).clamp(0, initialSeconds);
    final int minutes = (secondsSpent / 60).round();

    final userRef = _firestore.collection('users').doc(uid);
    final sessionRef = _firestore.collection('pomodoro_sessions').doc();

    await _firestore.runTransaction((transaction) async {
      // Create session doc and mark awarded true in same transaction
      transaction.set(sessionRef, {
        'sessionId': sessionRef.id,
        'userId': uid,
        'durationMinutes': minutes,
        'secondsSpent': secondsSpent,
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': FieldValue.serverTimestamp(),
        'awarded': true,
      });

      if (minutes > 0) {
        transaction.update(userRef, {
          'studyPoints': FieldValue.increment(minutes),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Also ensure the user is marked inactive
      transaction.update(userRef, {
        'isPomodoroActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelPomodoro({required String uid}) async {
    await _firestore.collection('users').doc(uid).set({
      'isPomodoroActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> activeMembersStream() {
    return _firestore
        .collection('users')
        .where('isPomodoroActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList());
  }
}
