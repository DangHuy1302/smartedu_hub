import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rooms';

  // Lấy danh sách tất cả phòng học (Future)
  Future<List<RoomModel>> getAllRooms() async {
    try {
      final snapshot = await _firestore.collection(_collection).where('isActive', isEqualTo: true).get();
      return snapshot.docs.map((doc) => RoomModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách phòng: $e');
    }
  }

  // Stream danh sách phòng realtime
  Stream<List<RoomModel>> streamRooms() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RoomModel.fromJson(doc.data(), doc.id)).toList());
  }

  // Cập nhật số ghế trống sau khi book
  Future<void> updateAvailableSeats(String roomId, int newAvailableSeats) async {
    try {
      await _firestore.collection(_collection).doc(roomId).update({
        'availableSeats': newAvailableSeats,
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật chỗ ngồi: $e');
    }
  }
}
