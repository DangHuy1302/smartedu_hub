import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Lưu ý: Nên chuyển cái này vào file config riêng hoặc biến môi trường
const String googleCloudApiKey = '<YOUR_GOOGLE_CLOUD_API_KEY>';

class OcrDocumentService {
  static final OcrDocumentService _instance = OcrDocumentService._internal();
  factory OcrDocumentService() => _instance;
  OcrDocumentService._internal();

  static const String _visionApiBase = 'https://vision.googleapis.com/v1/images:annotate';
  static const String _translateApiBase = 'https://translation.googleapis.com/language/translate/v2';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickDocumentImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  Future<String> extractTextFromImage(XFile file) async {
    if (googleCloudApiKey.startsWith('<')) {
      throw StateError('Google Cloud API key chưa được cấu hình.');
    }

    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    final uri = Uri.parse('$_visionApiBase?key=$googleCloudApiKey');
    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': encoded},
          'features': [{'type': 'TEXT_DETECTION', 'maxResults': 1}],
        },
      ],
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Vision API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final firstResponse = (decoded['responses'] as List<dynamic>?)?.first as Map<String, dynamic>?;
    final detection = firstResponse?['fullTextAnnotation'] as Map<String, dynamic>?;
    return detection != null ? (detection['text'] as String? ?? '') : '';
  }

  Future<String> translateToVietnamese(String text) async {
    if (googleCloudApiKey.startsWith('<')) return text;

    final uri = Uri.parse('$_translateApiBase?key=$googleCloudApiKey');
    final body = jsonEncode({
      'q': [text],
      'target': 'vi',
      'format': 'text',
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) throw Exception('Translation error');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final translations = (decoded['data'] as Map<String, dynamic>?)?['translations'] as List<dynamic>?;
    return translations?.first['translatedText'] as String? ?? '';
  }

  Future<String?> uploadImageToStorage(XFile file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref().child('ocr_images/$fileName');
      final bytes = await file.readAsBytes();
      final snapshot = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<DocumentReference> saveDocument({
    required String title,
    required String extractedText,
    required String translatedText,
    XFile? imageFile,
    String language = 'en',
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImageToStorage(imageFile);
    }

    // Đồng bộ các key với OcrDocumentModel
    return await _firestore.collection('ocr_documents').add({
      'title': title,
      'userId': user.uid,
      'extractedText': extractedText,
      'translatedText': translatedText,
      'imageUrl': imageUrl ?? '',
      'language': language,
      'wordCount': extractedText.split(' ').length,
      'audioStatus': 'none',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
