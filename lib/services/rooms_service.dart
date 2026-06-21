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
    return _db.collection('bookings').where('userId', isEqualTo: userId).where('status', whereIn: ['Confirmed']).snapshots().map((snap) =>
        snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return {'id': d.id, ...data};
        }).toList());
  }

  Future<Map<String, dynamic>?> getActiveBookingForUserAndRoom(String userId, String roomId) async {
    final q = await _db.collection('bookings').where('userId', isEqualTo: userId).where('roomId', isEqualTo: roomId).where('status', isEqualTo: 'Confirmed').limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    final data = Map<String, dynamic>.from(d.data() as Map);
    return {'id': d.id, ...data};
  }

  /// Attempts to book `seatCount` seats in `roomId` for `userId`.
  /// Returns bookingId on success, throws on failure.
  Future<String> bookRoom({required String userId, required String roomId, required int seatCount, required DateTime bookingDate, required String startTime, required String endTime}) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    final bookingRef = _db.collection('bookings').doc();

    return _db.runTransaction((tx) async {
      final roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) throw Exception('Room not found');

      final data = roomSnap.data() as Map<String, dynamic>;
      final available = (data['availableSeats'] ?? 0) as int;

      if (available < seatCount) throw Exception('Không đủ ghế trống');

      // decrement seats
      tx.update(roomRef, {'availableSeats': available - seatCount});

      // create booking
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

  /// Cancel a booking (mark status Cancelled) and increment room.availableSeats by seatCount.
  Future<void> cancelBooking({required String bookingId}) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found');
      final booking = bookingSnap.data() as Map<String, dynamic>;
      final roomId = booking['roomId'] as String;
      final seatCount = (booking['seatCount'] ?? 0) as int;

      final roomRef = _db.collection('rooms').doc(roomId);
      final roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) throw Exception('Room not found');

      final roomData = roomSnap.data() as Map<String, dynamic>;
      final available = (roomData['availableSeats'] ?? 0) as int;

      // increment seats and mark booking cancelled
      tx.update(roomRef, {'availableSeats': available + seatCount});
      tx.update(bookingRef, {'status': 'Cancelled', 'cancelledAt': Timestamp.now()});
    });
  }
}
