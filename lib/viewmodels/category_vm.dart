import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  // Load categories from Firestore
  Future<void> fetchCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    _categories = snapshot.docs
        .map((doc) => CategoryModel.fromDocument(doc))
        .toList();
    notifyListeners();
  }

  // Add a new category to Firestore
  Future<void> addCategory(CategoryModel category) async {
    final docRef = await _firestore.collection('categories').add(category.toMap());
    _categories.add(CategoryModel(
      categoryId: docRef.id,
      name: category.name,
      icon: category.icon,
    ));
    notifyListeners();
  }

  // Remove category from Firestore
  Future<void> removeCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
    _categories.removeWhere((c) => c.categoryId == categoryId);
    notifyListeners();
  }
}
