import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';
import 'photo_model.dart';

class UnSeenModel {
  final String unseenId;
  final String title;
  final String story;
  final LocationModel location;
  final List<PhotoModel> photos;
  final List<String> categories;
  final String creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UnSeenModel({
    required this.unseenId,
    required this.title,
    required this.story,
    required this.location,
    required this.photos,
    required this.categories,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
  });

  UnSeenModel copyWith({
    String? unseenId,
    String? title,
    String? story,
    LocationModel? location,
    List<PhotoModel>? photos,
    List<String>? categories,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnSeenModel(
      unseenId: unseenId ?? this.unseenId,
      title: title ?? this.title,
      story: story ?? this.story,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      categories: categories ?? this.categories,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UnSeenModel.fromMap(Map<String, dynamic> map, String id) {
    return UnSeenModel(
      unseenId: id,
      title: map['title'] ?? '',
      story: map['story'] ?? '',
      location: LocationModel.fromMap(map['location']),
      photos: map['photos'] != null
          ? List<PhotoModel>.from(map['photos'].map((p) => PhotoModel.fromMap(p)))
          : [],
      categories: List<String>.from(map['categories'] ?? []),
      creatorId: map['creatorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'story': story,
      'location': location.toMap(),
      'photos': photos.map((p) => p.toMap()).toList(),
      'categories': categories,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

