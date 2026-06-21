import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BookingModel extends Equatable {
  final String bookingId;
  final String userId;
  final String roomId;
  final int seatCount;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final bool emailSent;
  final DateTime? createdAt;

  const BookingModel({
    required this.bookingId,
    required this.userId,
    required this.roomId,
    required this.seatCount,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.emailSent = false,
    this.createdAt,
  });

  BookingModel copyWith({
    String? bookingId,
    String? userId,
    String? roomId,
    int? seatCount,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    String? status,
    bool? emailSent,
    DateTime? createdAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      seatCount: seatCount ?? this.seatCount,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      emailSent: emailSent ?? this.emailSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json, String documentId) {
    return BookingModel(
      bookingId: documentId,
      userId: json['userId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      seatCount: json['seatCount'] as int? ?? 1,
      bookingDate: (json['bookingDate'] as Timestamp).toDate(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      emailSent: json['emailSent'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'roomId': roomId,
      'seatCount': seatCount,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'emailSent': emailSent,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        bookingId, userId, roomId, seatCount, bookingDate, 
        startTime, endTime, status, emailSent, createdAt
      ];
}
