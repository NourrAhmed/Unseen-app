import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String categoryId; 
  final String name;
  final String? icon;

  CategoryModel({
    required this.categoryId,
    required this.name,
    this.icon,
  });

  
  factory CategoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      categoryId: doc.id, 
      name: data['name'] ?? '',
      icon: data['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}
