import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String? studentId;
  final String? avatarUrl;
  final int studyPoints;
  final int totalBookings;
  final bool isPomodoroActive;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.studentId,
    this.avatarUrl,
    this.studyPoints = 0,
    this.totalBookings = 0,
    this.isPomodoroActive = false,
    this.status='offline',
    this.createdAt,
    this.updatedAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? studentId,
    String? avatarUrl,
    int? studyPoints,
    int? totalBookings,
    String? status,
    bool? isPomodoroActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      studyPoints: studyPoints ?? this.studyPoints,
      totalBookings: totalBookings ?? this.totalBookings,
      isPomodoroActive: isPomodoroActive ?? this.isPomodoroActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid: documentId,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      studentId: json['studentId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      studyPoints: json['studyPoints'] as int? ?? 0,
      totalBookings: json['totalBookings'] as int? ?? 0,
      isPomodoroActive: json['isPomodoroActive'] as bool? ?? false,
      status: json['status'] as String? ?? 'offline',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'studentId': studentId,
      'avatarUrl': avatarUrl,
      'studyPoints': studyPoints,
      'totalBookings': totalBookings,
      'isPomodoroActive': isPomodoroActive,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [uid, email, fullName, studentId, avatarUrl, studyPoints, totalBookings, isPomodoroActive, status, createdAt, updatedAt];
}
