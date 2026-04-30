import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String? documentId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LocationModel({
    this.documentId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      documentId: map['documentId'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
