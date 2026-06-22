import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/google_cloud_api_config.dart';

class OcrDocumentService {
  static final OcrDocumentService _instance = OcrDocumentService._internal();
  factory OcrDocumentService() => _instance;
  OcrDocumentService._internal();

  static const String _visionApiBase =
      'https://vision.googleapis.com/v1/images:annotate';
  static const String _translateApiBase =
      'https://translation.googleapis.com/language/translate/v2';

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
      throw StateError(
        'Google Cloud API key is not configured. Please update google_cloud_api_config.dart.',
      );
    }

    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    final uri = Uri.parse('$_visionApiBase?key=$googleCloudApiKey');
    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': encoded},
          'features': [
            {'type': 'TEXT_DETECTION', 'maxResults': 1},
          ],
        },
      ],
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Vision API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final firstResponse =
        (decoded['responses'] as List<dynamic>?)?.first
            as Map<String, dynamic>?;
    final detection =
        firstResponse?['fullTextAnnotation'] as Map<String, dynamic>?;
    return detection != null ? (detection['text'] as String? ?? '') : '';
  }

  Future<String> translateToVietnamese(String text) async {
    if (googleCloudApiKey.startsWith('<')) {
      throw StateError(
        'Google Cloud API key is not configured. Please update google_cloud_api_config.dart.',
      );
    }

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

    if (response.statusCode != 200) {
      throw Exception(
        'Translation API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final translations =
        (decoded['data'] as Map<String, dynamic>?)?['translations']
            as List<dynamic>?;
    return translations?.first['translatedText'] as String? ?? '';
  }

  Future<String?> uploadImageToStorage(XFile file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('ocr_images/$fileName');
    final bytes = await file.readAsBytes();
    final snapshot = await ref.putData(bytes);
    return await snapshot.ref.getDownloadURL();
  }

  Future<DocumentReference> saveDocument({
    required String title,
    required String englishText,
    required String vietnameseText,
    XFile? imageFile,
    String? audioUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    final imageUrl = imageFile != null
        ? await uploadImageToStorage(imageFile)
        : null;
    return await _firestore.collection('ocr_documents').add({
      'title': title,
      'englishText': englishText,
      'vietnameseText': vietnameseText,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user?.uid,
      'ownerEmail': user?.email,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    });
  }

  Stream<QuerySnapshot> watchDocuments() {
    return _firestore
        .collection('ocr_documents')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
