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
}
