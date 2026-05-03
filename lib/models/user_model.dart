import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String photoURL;
  final String bio;
  final List<String> interests;
  final String role;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.photoURL,
    required this.bio,
    required this.interests,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        phoneNumber: json['phoneNumber'] as String? ?? '',
        photoURL: json['photoURL'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        interests: List<String>.from(json['interests'] as List? ?? []),
        role: json['role'] as String? ?? 'user',
        createdAt: json['createdAt'] as Timestamp,
        updatedAt: json['updatedAt'] as Timestamp,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        'bio': bio,
        'interests': interests,
        'role': role,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
