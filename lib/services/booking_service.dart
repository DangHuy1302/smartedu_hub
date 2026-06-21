import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  // Tạo booking mới
  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore.collection(_collection).add(booking.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo booking: $e');
    }
  }

  // Lấy lịch sử booking của một user cụ thể (Future)
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => BookingModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy lịch sử booking: $e');
    }
  }

  // Lắng nghe trạng thái booking realtime
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromJson(doc.data(), doc.id)).toList());
  }

  // Cập nhật trạng thái booking (ví dụ: 'cancelled', 'completed')
  Future<void> updateStatus(String bookingId, String status) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({'status': status});
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái booking: $e');
    }
  }
}
