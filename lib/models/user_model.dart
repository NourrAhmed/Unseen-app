import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String userId;
  final String email;
  final String? profileImageUrl;
  final String username;
  final String phone;
  final List<String> userUnseens; 
  final List<String> savedUnseens; 
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    this.profileImageUrl,
    required this.username,
    required this.phone,
    required this.userUnseens,
    required this.savedUnseens,
    required this.createdAt,
  });

  factory UserModel.fromFirebase(User firebaseUser, Map<String, dynamic>? firestoreData) {
    print('🔍 Creating UserModel from Firebase data: $firestoreData');
    
    // Try to get profile image from Firestore first, then fall back to Firebase Auth
    String? profileImage = firestoreData?['profileImageUrl'] as String?;
    
    if (profileImage == null || profileImage.isEmpty) {
      profileImage = firebaseUser.photoURL;
    }
    
    print('🔍 Profile image URL: $profileImage');
    
    return UserModel(
      userId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      profileImageUrl: profileImage,
      username: firestoreData?['username'] ?? '',
      phone: firestoreData?['phone'] ?? '',
      userUnseens: List<String>.from(firestoreData?['userUnseens'] ?? []),
      savedUnseens: List<String>.from(firestoreData?['savedUnseens'] ?? []),
      createdAt: (firestoreData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'userUnseens': userUnseens,
      'savedUnseens': savedUnseens,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? profileImageUrl,
    String? username,
    String? phone,
    List<String>? userUnseens,
    List<String>? savedUnseens,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      userUnseens: userUnseens ?? this.userUnseens,
      savedUnseens: savedUnseens ?? this.savedUnseens,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
