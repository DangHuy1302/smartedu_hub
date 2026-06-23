import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OcrDocumentModel extends Equatable {
  final String documentId;
  final String userId;
  final String title;
  final String imageUrl;
  final String extractedText;
  final String? translatedText; 
  final String? audioUrl;
  final String? audioStatus; // 'none', 'generating', 'ready', 'error'
  final String language;
  final int wordCount;
  final DateTime? createdAt;

  const OcrDocumentModel({
    required this.documentId,
    required this.title,
    required this.imageUrl,
    required this.extractedText,
    required this.userId,
    this.translatedText,
    this.audioUrl,
    this.audioStatus,
    required this.language,
    required this.wordCount,
    this.createdAt,
  });

  factory OcrDocumentModel.fromJson(Map<String, dynamic> json, String documentId) {
    return OcrDocumentModel(
      documentId: documentId,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'Tài liệu không tên',
      imageUrl: json['imageUrl'] as String? ?? '',
      extractedText: json['extractedText'] as String? ?? '',
      translatedText: json['translatedText'] as String?,
      audioUrl: json['audioUrl'] as String?,
      audioStatus: json['audioStatus'] as String? ?? 'none',
      language: json['language'] as String? ?? 'en',
      wordCount: json['wordCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory OcrDocumentModel.fromFirestore(DocumentSnapshot doc) {
    return OcrDocumentModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'userId': userId,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
      'audioUrl': audioUrl,
      'audioStatus': audioStatus,
      'language': language,
      'wordCount': wordCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  OcrDocumentModel copyWith({
    String? documentId,
    String? userId,
    String? title,
    String? imageUrl,
    String? extractedText,
    String? translatedText,
    String? audioUrl,
    String? audioStatus,
    String? language,
    int? wordCount,
    DateTime? createdAt,
  }) {
    return OcrDocumentModel(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedText: extractedText ?? this.extractedText,
      translatedText: translatedText ?? this.translatedText,
      audioUrl: audioUrl ?? this.audioUrl,
      audioStatus: audioStatus ?? this.audioStatus,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        documentId, userId, title, imageUrl, 
        extractedText, translatedText, audioUrl, audioStatus, language, wordCount, createdAt
      ];
}
