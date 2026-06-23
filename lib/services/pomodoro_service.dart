import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Bắt đầu phiên học mới và gán ID phòng hiện tại
  Future<void> startPomodoro({required String uid, String? roomId}) async {
    final data = {
      'isPomodoroActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'focusing',
      'pomodoroStartedAt': FieldValue.serverTimestamp(),
    };
    if (roomId != null) {
      data['currentRoomId'] = roomId;
    }
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Cập nhật thời gian còn lại định kỳ
  Future<void> syncRemainingTime({required String uid, required int remainingSeconds}) async {
    await _firestore.collection('users').doc(uid).update({
      'pomodoroRemainingSeconds': remainingSeconds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kết thúc phiên học và xóa thông tin phòng
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
        'currentRoomId': FieldValue.delete(), // Xóa phòng khi kết thúc
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
      'currentRoomId': FieldValue.delete(),
      'pomodoroRemainingSeconds': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy tất cả thành viên trong cùng một phòng (dựa vào currentRoomId)
  Stream<List<Map<String, dynamic>>> activeMembersStream(String? roomId) {
    if (roomId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .where('currentRoomId', isEqualTo: roomId)
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          return snap.docs
              .map((d) => {...d.data(), 'uid': d.id})
              .where((member) {
                // Nếu đang ở trạng thái 'left' quá 30 phút thì ẩn
                if (member['status'] == 'left') {
                  final leftAt = (member['pomodoroLeftAt'] as Timestamp?)?.toDate();
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
