// unseen_vm.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unseen_model.dart';

class UnSeenViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UnSeenModel> _unseens = [];

  List<UnSeenModel> get unseens => _unseens;

  // Fetch all UnSeens from Firestore
  Future<void> fetchUnSeens() async {
    final snapshot = await _firestore.collection('unseens').get();
    _unseens = snapshot.docs
        .map((doc) => UnSeenModel.fromMap(doc.data(), doc.id))
        .toList();
    notifyListeners();
  }

  // Add UnSeen to Firestore and return the model with ID
  Future<UnSeenModel> addUnSeenToFirestore(UnSeenModel unseen) async {
    final docRef = await _firestore.collection('unseens').add(unseen.toMap());
    final unseenWithId = unseen.copyWith(unseenId: docRef.id);
    _unseens.add(unseenWithId);
    notifyListeners();
    return unseenWithId;
  }

  // Update UnSeen
  Future<void> updateUnSeen(UnSeenModel unseen) async {
    await _firestore.collection('unseens').doc(unseen.unseenId).update(unseen.toMap());
    final index = _unseens.indexWhere((e) => e.unseenId == unseen.unseenId);
    if (index != -1) {
      _unseens[index] = unseen;
      notifyListeners();
    }
  }

  // Delete UnSeen
  Future<void> deleteUnSeen(String unseenId) async {
    await _firestore.collection('unseens').doc(unseenId).delete();
    _unseens.removeWhere((e) => e.unseenId == unseenId);
    notifyListeners();
  }
}

