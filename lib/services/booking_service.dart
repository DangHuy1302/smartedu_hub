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

  // Tích hợp gửi email qua Firestore Extension (Zoho Mail)
  Future<void> sendBookingEmail({
    required String userEmail,
    required String userName,
    required String roomName,
    required String bookingId,
    required String startTime,
    required String date,
  }) async {
    try {
      await _firestore.collection('mail').add({
        'to': userEmail,
        'message': {
          'subject': '[SmartEdu Hub] Xác nhận đặt chỗ thành công',
          'html': '''
            <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
              <h2 style="color: #0046ad;">Xác nhận đặt chỗ thành công!</h2>
              <p>Chào <b>$userName</b>,</p>
              <p>Chúc mừng bạn đã đặt chỗ thành công tại hệ thống <b>SmartEdu Hub</b>.</p>
              <hr>
              <p><b>Thông tin chi tiết:</b></p>
              <ul>
                <li><b>Phòng học:</b> $roomName</li>
                <li><b>Ngày:</b> $date</li>
                <li><b>Giờ bắt đầu:</b> $startTime</li>
                <li><b>Mã số giữ chỗ:</b> <span style="color: #d9534f; font-weight: bold;">$bookingId</span></li>
              </ul>
              <p>Vui lòng đến đúng giờ để có trải nghiệm học tập tốt nhất.</p>
              <br>
              <p>Trân trọng,<br><b>Đội ngũ SmartEdu Hub - Nhóm 5</b></p>
            </div>
          ''',
        },
      });
    } catch (e) {
      print('Lỗi khi ghi vào collection mail: $e');
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
