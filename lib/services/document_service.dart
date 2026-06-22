import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ocr_document.dart';
import 'tts_service.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'ocr_documents';

  Stream<List<OcrDocumentModel>> getDocumentsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestore.collection(_collection).where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => OcrDocumentModel.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> processPodcastGeneration(OcrDocumentModel doc) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Cập nhật trạng thái đang tạo
      await _firestore.collection(_collection).doc(doc.documentId).update({'audioStatus': 'generating'});

      String textToRead = doc.extractedText;
      if (doc.translatedText != null && doc.translatedText!.isNotEmpty) {
        textToRead = doc.translatedText!;
      }

      // 2. Gọi TTS với Timeout 30 giây (tránh treo vô hạn)
      final ttsService = TtsService();
      final String? downloadUrl = await ttsService.generateRemotePodcast(
        docId: doc.documentId,
        text: textToRead,
        userId: uid,
      ).timeout(const Duration(seconds: 30));

      if (downloadUrl != null) {
        // 3. Thành công
        await _firestore.collection(_collection).doc(doc.documentId).update({
          'audioUrl': downloadUrl,
          'audioStatus': 'ready',
        });
      }
    } catch (e) {
      print("LỖI TẠO PODCAST: $e");
      // 4. Khi lỗi phải cập nhật về 'error' để UI hiện nút "Thử lại" thay vì quay mãi
      await _firestore.collection(_collection).doc(doc.documentId).update({
        'audioStatus': 'error',
      });
    }
  }
}