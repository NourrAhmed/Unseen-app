import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoModel {
  final String url;
  final DateTime uploadedAt;
  final String uploadedBy;

  PhotoModel({
    required this.url,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      url: map['url'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }
}
