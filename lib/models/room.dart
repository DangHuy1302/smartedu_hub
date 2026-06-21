
import 'package:equatable/equatable.dart';

class RoomModel extends Equatable {
  final String roomId;
  final String name;
  final String type;
  final String address;
  final int totalSeats;
  final int availableSeats;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final bool isActive;

  const RoomModel({
    required this.roomId,
    required this.name,
    required this.type,
    required this.address,
    required this.totalSeats,
    required this.availableSeats,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
  });

  RoomModel copyWith({
    String? roomId,
    String? name,
    String? type,
    String? address,
    int? totalSeats,
    int? availableSeats,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json, String documentId) {
    return RoomModel(
      roomId: documentId,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      address: json['address'] as String? ?? '',
      totalSeats: json['totalSeats'] as int? ?? 0,
      availableSeats: json['availableSeats'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
        roomId, name, type, address, totalSeats, availableSeats,
        description, imageUrl, latitude, longitude, isActive
      ];
}
