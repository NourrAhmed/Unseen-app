import 'package:cloud_firestore/cloud_firestore.dart';

class SearchModel {
  final String query;
  final List<String> categories;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final DateTime timestamp;

  SearchModel({
    required this.query,
    required this.categories,
    this.latitude,
    this.longitude,
    this.radiusKm,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to Firestore format (for saving search history)
  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'categories': categories,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create from Firestore document (for loading search history)
  factory SearchModel.fromMap(Map<String, dynamic> map) {
    return SearchModel(
      query: map['query'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      latitude: map['latitude'],
      longitude: map['longitude'],
      radiusKm: map['radiusKm'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore DocumentSnapshot (with timestamp)
  factory SearchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchModel(
      query: data['query'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      latitude: data['latitude'],
      longitude: data['longitude'],
      radiusKm: data['radiusKm'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method for creating modified copies
  SearchModel copyWith({
    String? query,
    List<String>? categories,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? timestamp,
  }) {
    return SearchModel(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'SearchModel(query: $query, categories: $categories, lat: $latitude, lng: $longitude, radius: $radiusKm, timestamp: $timestamp)';
  }

  // Display text for search history
  String get displayText {
    if (query.isNotEmpty) {
      return query;
    } else if (categories.isNotEmpty) {
      return categories.join(', ');
    } else {
      return 'Location search';
    }
  }
}