import 'package:cloud_firestore/cloud_firestore.dart';

class OcrDocument {
  final String id;
  final String title;
  final String englishText;
  final String vietnameseText;
  final DateTime? createdAt;
  final String? ownerId;
  final String? ownerEmail;
  final String? imageUrl;
  final String? audioUrl;

  OcrDocument({
    required this.id,
    required this.title,
    required this.englishText,
    required this.vietnameseText,
    required this.createdAt,
    this.ownerId,
    this.ownerEmail,
    this.imageUrl,
    this.audioUrl,
  });

  factory OcrDocument.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['createdAt'];
    return OcrDocument(
      id: snapshot.id,
      title: data['title'] as String? ?? 'Không tên',
      englishText: data['englishText'] as String? ?? '',
      vietnameseText: data['vietnameseText'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      ownerId: data['ownerId'] as String?,
      ownerEmail: data['ownerEmail'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'englishText': englishText,
      'vietnameseText': vietnameseText,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }
}
