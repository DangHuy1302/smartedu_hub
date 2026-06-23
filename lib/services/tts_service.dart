import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../secret.dart';

class TtsService {
  // Use the same local API key stored in lib/secret.dart
  final String _apiKey = GOOGLE_CLOUD_API_KEY;

  Future<String?> generateRemotePodcast({
    required String docId,
    required String text,
    required String userId,
  }) async {
    try {
      if (text.trim().isEmpty) throw Exception("Văn bản trống.");

      print("TTS Service: Đang gọi Google Cloud TTS...");
      const String url =
          'https://texttospeech.googleapis.com/v1/text:synthesize';

      final response = await http.post(
        Uri.parse('$url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "input": {"text": text},
          "voice": {
            "languageCode": "vi-VN",
            "name": "vi-VN-Wavenet-D",
            "ssmlGender": "FEMALE",
          },
          "audioConfig": {
            "audioEncoding": "MP3",
            "pitch": 0,
            "speakingRate": 1.0,
          },
        }),
      );

      if (response.statusCode != 200) {
        final errorInfo =
            jsonDecode(response.body)['error']?['message'] ?? response.body;
        throw Exception("API Error: $errorInfo");
      }

      final String? audioContent = jsonDecode(response.body)['audioContent'];
      if (audioContent == null)
        throw Exception("Không có dữ liệu audioContent.");

      final Uint8List audioBytes = base64Decode(audioContent);
      print("TTS Service: Đang upload lên Storage...");

      final String storagePath = 'podcasts/$userId/$docId.mp3';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Metadata chuẩn cho file MP3 trên trình duyệt
      final metadata = SettableMetadata(
        contentType: 'audio/mpeg',
        cacheControl: 'public,max-age=3600',
      );

      // putData trả về UploadTask, ta đợi snapshot để đảm bảo kết thúc hoặc lỗi
      final uploadTask = storageRef.putData(audioBytes, metadata);

      // Chờ cho đến khi upload hoàn tất. Nếu lỗi CORS, Exception sẽ ném ra tại đây ngay lập tức.
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print("TTS Service: Tạo Podcast thành công!");

      return downloadUrl;
    } catch (e) {
      print("TTS Service Error: $e");
      rethrow;
    }
  }
}
