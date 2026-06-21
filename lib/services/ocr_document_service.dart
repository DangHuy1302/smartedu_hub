import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ocr_document.dart';

class OcrDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ocr_documents';

  // Lưu document mới sau khi OCR thành công
  Future<String> saveDocument(OcrDocumentModel document) async {
    try {
      final docRef = await _firestore.collection(_collection).add(document.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi lưu tài liệu OCR: $e');
    }
  }

  // Lắng nghe danh sách tài liệu OCR của user realtime
  Stream<List<OcrDocumentModel>> streamUserDocuments(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => OcrDocumentModel.fromJson(doc.data(), doc.id)).toList());
  }

  // Xóa document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Lỗi xóa lịch sử OCR: $e');
    }
  }
}
