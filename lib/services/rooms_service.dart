import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> streamRooms() {
    return _db.collection('rooms').snapshots().map((snap) =>
        snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return {'id': d.id, ...data};
        }).toList());
  }

  Stream<List<Map<String, dynamic>>> streamUserBookings(String userId) {
    return _db.collection('bookings').where('userId', isEqualTo: userId).where('status', isEqualTo: 'Confirmed').snapshots().map((snap) =>
        snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return {'id': d.id, ...data};
        }).toList());
  }

  Future<Map<String, dynamic>?> getActiveBookingForUser(String userId) async {
    // Trước khi lấy booking active, hãy kiểm tra và dọn dẹp nếu nó quá hạn
    await cleanupUserBooking(userId);

    final q = await _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Confirmed')
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    final data = Map<String, dynamic>.from(d.data() as Map);
    return {'id': d.id, ...data};
  }

  /// Kiểm tra và hủy booking của 1 user cụ thể nếu quá 30p không hoạt động
  Future<void> cleanupUserBooking(String userId) async {
    final now = DateTime.now();
    final bookings = await _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Confirmed')
        .get();

    if (bookings.docs.isEmpty) return;

    final userDoc = await _db.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final status = userData?['status'];
    final lastUpdate = (userData?['updatedAt'] as Timestamp?)?.toDate();
    final leftAt = (userData?['pomodoroLeftAt'] as Timestamp?)?.toDate();

    for (var doc in bookings.docs) {
      final bookingData = doc.data();
      final createdAt = (bookingData['createdAt'] as Timestamp?)?.toDate() ?? now;
      bool shouldCancel = false;

      // 1. Nếu chưa từng bắt đầu học (không có status) và quá 30p từ khi đặt
      if (status == null) {
        if (now.difference(createdAt).inMinutes >= 30) {
          shouldCancel = true;
        }
      }
      // 2. Nếu đang ở trạng thái tạm dừng hoặc đã rời đi quá 30p
      else if (status == 'paused' || status == 'left') {
        final timeToCheck = leftAt ?? lastUpdate ?? createdAt;
        if (now.difference(timeToCheck).inMinutes >= 30) {
          shouldCancel = true;
        }
      }
      // 3. Nếu không phải đang học (focusing) mà quá 30p không cập nhật
      else if (status != 'focusing') {
        final timeToCheck = lastUpdate ?? createdAt;
        if (now.difference(timeToCheck).inMinutes >= 30) {
          shouldCancel = true;
        }
      }

      if (shouldCancel) {
        await cancelBooking(bookingId: doc.id);
        print('Auto-cancelled stale booking: ${doc.id} for user: $userId');
      }
    }
  }

  /// (Tùy chọn) Hàm dọn dẹp toàn bộ hệ thống - Có thể gọi bởi Admin hoặc định kỳ
  Future<void> globalCleanup() async {
    final confirmedBookings = await _db.collection('bookings')
        .where('status', isEqualTo: 'Confirmed')
        .get();

    for (var doc in confirmedBookings.docs) {
      final userId = doc.data()['userId'];
      if (userId != null) {
        await cleanupUserBooking(userId);
      }
    }
  }

  Future<String> bookRoom({required String userId, required String roomId, required int seatCount, required DateTime bookingDate, required String startTime, required String endTime}) async {
    if (seatCount > 5) throw Exception('Bạn chỉ có thể đặt tối đa 5 ghế');

    final roomRef = _db.collection('rooms').doc(roomId);
    final bookingRef = _db.collection('bookings').doc();
    final userRef = _db.collection('users').doc(userId);

    return _db.runTransaction((tx) async {
      final userBookingsQuery = await _db.collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Confirmed')
          .get();
      
      if (userBookingsQuery.docs.isNotEmpty) {
        throw Exception('Bạn đã có một phòng đang đặt. Vui lòng hoàn tác trước khi đặt phòng mới.');
      }

      final roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) throw Exception('Room not found');

      final data = roomSnap.data() as Map<String, dynamic>;
      final available = (data['availableSeats'] ?? 0) as int;

      if (available < seatCount) throw Exception('Không đủ ghế trống');

      tx.update(roomRef, {'availableSeats': available - seatCount});
      tx.set(userRef, {'currentRoomId': roomId}, SetOptions(merge: true));

      final bookingData = {
        'bookingId': bookingRef.id,
        'userId': userId,
        'roomId': roomId,
        'seatCount': seatCount,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'startTime': startTime,
        'endTime': endTime,
        'status': 'Confirmed',
        'emailSent': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      tx.set(bookingRef, bookingData);
      return bookingRef.id;
    });
  }

  Future<void> cancelBooking({required String bookingId}) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found');
      final booking = bookingSnap.data() as Map<String, dynamic>;
      
      if (booking['status'] != 'Confirmed') return;

      final roomId = booking['roomId'] as String;
      final userId = booking['userId'] as String;
      final seatCount = (booking['seatCount'] ?? 0) as int;

      final roomRef = _db.collection('rooms').doc(roomId);
      final userRef = _db.collection('users').doc(userId);
      final roomSnap = await tx.get(roomRef);
      
      if (roomSnap.exists) {
        final roomData = roomSnap.data() as Map<String, dynamic>;
        final available = (roomData['availableSeats'] ?? 0) as int;
        tx.update(roomRef, {'availableSeats': available + seatCount});
      }

      tx.update(userRef, {'currentRoomId': FieldValue.delete()});
      tx.update(bookingRef, {'status': 'Cancelled', 'cancelledAt': FieldValue.serverTimestamp()});
    });
  }
}
