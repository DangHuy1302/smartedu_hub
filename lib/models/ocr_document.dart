import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OcrDocumentModel extends Equatable {
  final String documentId;
  final String userId;
  final String title;
  final String originalFileUrl;
  final String extractedText;
  final String? audioUrl;
  final String language;
  final int wordCount;
  final DateTime? createdAt;

  const OcrDocumentModel({
    required this.documentId,
    required this.userId,
    required this.title,
    required this.originalFileUrl,
    required this.extractedText,
    this.audioUrl,
    required this.language,
    required this.wordCount,
    this.createdAt,
  });

  OcrDocumentModel copyWith({
    String? documentId,
    String? userId,
    String? title,
    String? originalFileUrl,
    String? extractedText,
    String? audioUrl,
    String? language,
    int? wordCount,
    DateTime? createdAt,
  }) {
    return OcrDocumentModel(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      originalFileUrl: originalFileUrl ?? this.originalFileUrl,
      extractedText: extractedText ?? this.extractedText,
      audioUrl: audioUrl ?? this.audioUrl,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OcrDocumentModel.fromJson(Map<String, dynamic> json, String documentId) {
    return OcrDocumentModel(
      documentId: documentId,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      originalFileUrl: json['originalFileUrl'] as String? ?? '',
      extractedText: json['extractedText'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      language: json['language'] as String? ?? 'vi',
      wordCount: json['wordCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'originalFileUrl': originalFileUrl,
      'extractedText': extractedText,
      'audioUrl': audioUrl,
      'language': language,
      'wordCount': wordCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        documentId, userId, title, originalFileUrl, 
        extractedText, audioUrl, language, wordCount, createdAt
      ];
}
