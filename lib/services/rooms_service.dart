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
    final q = await _db.collection('bookings').where('userId', isEqualTo: userId).where('status', isEqualTo: 'Confirmed').limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    final data = Map<String, dynamic>.from(d.data() as Map);
    return {'id': d.id, ...data};
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
      // Cập nhật currentRoomId cho user ngay khi đặt chỗ
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
        'createdAt': Timestamp.now(),
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

      // Xóa currentRoomId khi hủy hoặc kết thúc
      tx.update(userRef, {'currentRoomId': FieldValue.delete()});
      tx.update(bookingRef, {'status': 'Cancelled', 'cancelledAt': Timestamp.now()});
    });
  }
}
