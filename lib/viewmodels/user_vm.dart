import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Load current user from Firebase Auth + Firestore
  Future<void> loadUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    final doc = await _db.collection("users").doc(user.uid).get();
    final data = doc.data();
    print('📱 Loading user data: $data');
    _currentUser = UserModel.fromFirebase(user, data);
    print('📱 Current user profile image: ${_currentUser?.profileImageUrl}');
    notifyListeners();
  }

  // Register user
  Future<String?> register(
    String email,
    String password,
    String username,
    String phone,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = credential.user!;

      await _db.collection("users").doc(user.uid).set({
        "username": username,
        "phone": phone,
        "userUnseens": [],
        "savedUnseens": [],
        "createdAt": Timestamp.now(),
      });

      await loadUser();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await loadUser();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile picture with base64 data URL
  Future<void> updateProfilePicture(String base64DataUrl) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Update Firestore document with base64 data URL
      await _db.collection('users').doc(user.uid).set({
        'profileImageUrl': base64DataUrl,
      }, SetOptions(merge: true));

      print('✅ Successfully updated profile picture');

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        profileImageUrl: base64DataUrl,
      );

      notifyListeners();
    } catch (e) {
      print('❌ Error updating profile picture: $e');
      rethrow;
    }
  }

  // Add unseen ID to user's "userUnseens" list (for created unseens)
  Future<void> addUserUnseen(String unseenId) async {
    if (_currentUser == null) {
      print('❌ Error: currentUser is null');
      return;
    }

    try {
      final docRef = _db.collection('users').doc(_currentUser!.userId);
      
      await docRef.set({
        'userUnseens': FieldValue.arrayUnion([unseenId])
      }, SetOptions(merge: true));

      print('✅ Successfully added unseen to user: $unseenId');

      _currentUser = _currentUser!.copyWith(
        userUnseens: [..._currentUser!.userUnseens, unseenId],
      );

      notifyListeners();
    } catch (e) {
      print('❌ Error adding user unseen: $e');
      rethrow;
    }
  }

  // Remove unseen ID from user's "userUnseens" list
  Future<void> removeUserUnseen(String unseenId) async {
    if (_currentUser == null) {
      print('❌ Error: currentUser is null');
      return;
    }

    try {
      final docRef = _db.collection('users').doc(_currentUser!.userId);
      
      await docRef.update({
        'userUnseens': FieldValue.arrayRemove([unseenId])
      });

      print('✅ Successfully removed unseen from user: $unseenId');

      final updatedList = _currentUser!.userUnseens.where((id) => id != unseenId).toList();
      _currentUser = _currentUser!.copyWith(userUnseens: updatedList);

      notifyListeners();
    } catch (e) {
      print('❌ Error removing user unseen: $e');
      rethrow;
    }
  }

  // Add unseen ID to user's "savedUnseens" list (for saved unseens from other users)
  Future<void> addSavedUnseen(String unseenId) async {
    if (_currentUser == null) {
      print('❌ Error: currentUser is null');
      return;
    }

    try {
      final docRef = _db.collection('users').doc(_currentUser!.userId);
      
      await docRef.set({
        'savedUnseens': FieldValue.arrayUnion([unseenId])
      }, SetOptions(merge: true));

      print('✅ Successfully added saved unseen: $unseenId');

      _currentUser = _currentUser!.copyWith(
        savedUnseens: [..._currentUser!.savedUnseens, unseenId],
      );

      notifyListeners();
    } catch (e) {
      print('❌ Error adding saved unseen: $e');
      rethrow;
    }
  }

  // Remove unseen ID from user's "savedUnseens" list
  Future<void> removeSavedUnseen(String unseenId) async {
    if (_currentUser == null) {
      print('❌ Error: currentUser is null');
      return;
    }

    try {
      final docRef = _db.collection('users').doc(_currentUser!.userId);
      
      await docRef.update({
        'savedUnseens': FieldValue.arrayRemove([unseenId])
      });

      print('✅ Successfully removed saved unseen: $unseenId');

      final updatedList = _currentUser!.savedUnseens.where((id) => id != unseenId).toList();
      _currentUser = _currentUser!.copyWith(savedUnseens: updatedList);

      notifyListeners();
    } catch (e) {
      print('❌ Error removing saved unseen: $e');
      rethrow;
    }
  }

  // Get username by user ID
  Future<String> getUsernameById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final username = doc.data()?['username'];
        print('✅ Fetched username for $userId: $username');
        return username ?? 'Unknown User';
      }
      print('❌ User document does not exist for: $userId');
      return 'Unknown User';
    } catch (e) {
      print('❌ Error fetching username for $userId: $e');
      return 'Unknown User';
    }
  }

  // Update user profile (username and phone)
  Future<void> updateUserProfile({
    required String username,
    required String phone,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final docRef = _db.collection('users').doc(_currentUser!.userId);
      
      await docRef.update({
        'username': username,
        'phone': phone,
      });

      print('✅ Successfully updated user profile');

      _currentUser = _currentUser!.copyWith(
        username: username,
        phone: phone,
      );

      notifyListeners();
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }
      // Check if a username already exists in Firestore (excluding current user)
  Future<bool> checkUsernameExists(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

      // Return true if another user has this username
    return query.docs.any((doc) => doc.id != _currentUser!.userId);
    }

  // Change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user logged in');
    }

    try {
      // Re-authenticate user with old password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
      
      print('✅ Password changed successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Error changing password: ${e.code}');
      rethrow;
    } catch (e) {
      print('❌ Error changing password: $e');
      rethrow;
    }
  }
}