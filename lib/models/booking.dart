class Booking {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final String status; // e.g., 'active', 'canceled'

  Booking({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    DateTime? createdAt,
    this.status = 'active',
  }) : createdAt = createdAt ?? DateTime.now();

  factory Booking.fromMap(Map<String, dynamic> m, String id) {
    return Booking(
      id: id,
      roomId: m['roomId'] as String? ?? '',
      userId: m['userId'] as String? ?? '',
      userName: m['userName'] as String? ?? '',
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: m['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
