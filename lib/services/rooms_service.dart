import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách phòng học - Chuẩn hóa dữ liệu tọa độ để hiện Markers ổn định trên Web
  Stream<List<Map<String, dynamic>>> streamRooms() {
    return _db.collection('rooms').snapshots().map((snap) =>
        snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return {
            ...data,
            'id': d.id,
            // Ép kiểu double an toàn cho tọa độ để không bị mất mốc trên Web
            'latitude': (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
            'longitude': (data['longitude'] ?? data['lng'] ?? 0.0).toDouble(),
            'availableSeats': (data['availableSeats'] ?? 0).toInt(),
            'totalSeats': (data['totalSeats'] ?? 0).toInt(),
          };
        }).toList());
  }

  // Lấy danh sách đặt chỗ của người dùng
  Stream<List<Map<String, dynamic>>> streamUserBookings(String userId) {
    return _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Confirmed')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return {'id': d.id, ...data};
        }).toList());
  }

  Future<Map<String, dynamic>?> getActiveBookingForUser(String userId) async {
    await cleanupUserBooking(userId);
    final q = await _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Confirmed')
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return {'id': d.id, ...Map<String, dynamic>.from(d.data() as Map)};
  }

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

      if (status == null) {
        if (now.difference(createdAt).inMinutes >= 30) shouldCancel = true;
      } else if (status == 'paused' || status == 'left') {
        final timeToCheck = leftAt ?? lastUpdate ?? createdAt;
        if (now.difference(timeToCheck).inMinutes >= 30) shouldCancel = true;
      } else if (status != 'focusing') {
        final timeToCheck = lastUpdate ?? createdAt;
        if (now.difference(timeToCheck).inMinutes >= 30) shouldCancel = true;
      }
      if (shouldCancel) await cancelBooking(bookingId: doc.id);
    }
  }

  Future<String> bookRoom({required String userId, required String roomId, required int seatCount, required DateTime bookingDate, required String startTime, required String endTime}) async {
    if (seatCount > 5) throw Exception('Bạn chỉ có thể đặt tối đa 5 ghế');

    final roomRef = _db.collection('rooms').doc(roomId);
    final bookingRef = _db.collection('bookings').doc();
    final userRef = _db.collection('users').doc(userId);

    final String bookingId = await _db.runTransaction((tx) async {
      final userBookingsQuery = await _db.collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      if (userBookingsQuery.docs.isNotEmpty) {
        throw Exception('Bạn đã có một phòng đang đặt.');
      }

      final roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) throw Exception('Room not found');

      final data = roomSnap.data() as Map<String, dynamic>;
      final available = (data['availableSeats'] ?? 0) as int;

      if (available < seatCount) throw Exception('Không đủ ghế trống');

      tx.update(roomRef, {'availableSeats': available - seatCount});
      tx.set(userRef, {'currentRoomId': roomId}, SetOptions(merge: true));

      tx.set(bookingRef, {
        'bookingId': bookingRef.id,
        'userId': userId,
        'roomId': roomId,
        'seatCount': seatCount,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'startTime': startTime,
        'endTime': endTime,
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return bookingRef.id;
    });

    _sendMailAfterBooking(userId, roomId, seatCount, bookingId);
    return bookingId;
  }

  void _sendMailAfterBooking(String userId, String roomId, int seatCount, String bookingId) {
    _db.collection('users').doc(userId).get().then((u) {
      if (u.exists && u.data()?['email'] != null) {
        _db.collection('rooms').doc(roomId).get().then((r) {
          _db.collection('mail').add({
            'to': u.data()?['email'],
            'message': {
              'subject': '[SmartEdu Hub] Đặt chỗ thành công',
              'html': 'Chào ${u.data()?['fullName']}, bạn đã đặt thành công $seatCount ghế tại ${r.data()?['name'] ?? 'Phòng học'}. Mã: $bookingId',
            }
          });
        });
      }
    });
  }

  Future<void> cancelBooking({required String bookingId}) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);
    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) return;
      final booking = bookingSnap.data() as Map<String, dynamic>;
      if (booking['status'] != 'Confirmed') return;

      final roomId = booking['roomId'] as String;
      final userId = booking['userId'] as String;
      final seatCount = (booking['seatCount'] ?? 0) as int;

      final roomRef = _db.collection('rooms').doc(roomId);
      final userRef = _db.collection('users').doc(userId);
      final roomSnap = await tx.get(roomRef);

      if (roomSnap.exists) {
        final available = (roomSnap.data()?['availableSeats'] ?? 0) as int;
        tx.update(roomRef, {'availableSeats': available + seatCount});
      }
      tx.update(userRef, {'currentRoomId': FieldValue.delete()});
      tx.update(bookingRef, {'status': 'Cancelled', 'cancelledAt': FieldValue.serverTimestamp()});
    });
  }
}
