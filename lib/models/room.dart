class Room {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int totalSeats;
  final int availableSeats;
  final String? description;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.totalSeats,
    required this.availableSeats,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Room.fromMap(Map<String, dynamic> m, String id) {
    return Room(
      id: id,
      name: m['name'] as String? ?? 'Unknown',
      lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
      totalSeats: (m['totalSeats'] as int?) ?? 0,
      availableSeats: (m['availableSeats'] as int?) ?? 0,
      description: m['description'] as String?,
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
