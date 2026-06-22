import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Bắt đầu phiên học mới
  Future<void> startPomodoro({required String uid}) async {
    await _firestore.collection('users').doc(uid).set({
      'isPomodoroActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'focusing',
      'pomodoroStartedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Cập nhật thời gian còn lại định kỳ (đề phòng crash)
  Future<void> syncRemainingTime({required String uid, required int remainingSeconds}) async {
    await _firestore.collection('users').doc(uid).update({
      'pomodoroRemainingSeconds': remainingSeconds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kết thúc phiên học và cộng điểm (1 phút = 1 điểm)
  Future<void> endPomodoro({
    required String uid,
    required int initialSeconds,
    required int secondsRemaining,
  }) async {
    final int secondsSpent = (initialSeconds - secondsRemaining).clamp(0, initialSeconds);
    final int minutes = (secondsSpent ~/ 60);

    final userRef = _firestore.collection('users').doc(uid);
    final sessionRef = _firestore.collection('pomodoro_sessions').doc();

    await _firestore.runTransaction((transaction) async {
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
        });
      }

      transaction.update(userRef, {
        'isPomodoroActive': false,
        'status': FieldValue.delete(),
        'pomodoroRemainingSeconds': FieldValue.delete(),
        'pomodoroStartedAt': FieldValue.delete(),
        'pomodoroLeftAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> pausePomodoro({required String uid, required int remainingSeconds}) async {
    await _firestore.collection('users').doc(uid).set({
      'isPomodoroActive': false,
      'status': 'paused',
      'pomodoroRemainingSeconds': remainingSeconds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resumePomodoro({required String uid}) async {
    await _firestore.collection('users').doc(uid).set({
      'isPomodoroActive': true,
      'status': 'focusing',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leavePomodoro({required String uid, required int remainingSeconds}) async {
    await _firestore.collection('users').doc(uid).set({
      'isPomodoroActive': false,
      'status': 'left',
      'pomodoroRemainingSeconds': remainingSeconds,
      'pomodoroLeftAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelPomodoro({required String uid}) async {
    await _firestore.collection('users').doc(uid).update({
      'isPomodoroActive': false,
      'status': FieldValue.delete(),
      'pomodoroRemainingSeconds': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> activeMembersStream() {
    return _firestore
        .collection('users')
        .where('status', whereIn: ['focusing', 'paused', 'left'])
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          return snap.docs
              .map((d) => {...d.data(), 'uid': d.id})
              .where((member) {
                if (member['status'] == 'left') {
                  final leftAt = (member['pomodoroLeftAt'] as Timestamp?)?.toDate();
                  // Nếu rời phòng quá 30 phút thì ẩn khỏi danh sách
                  if (leftAt != null && now.difference(leftAt).inMinutes >= 30) {
                    return false;
                  }
                }
                return true;
              })
              .toList();
        });
  }
}
