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
  final List<String> mutedCommunities;
  final bool isBanned;
  final String? banReason;
  final Timestamp? banExpiresAt;
  final String? durationLabel;
  final String? coverBannerUrl;

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
    required this.mutedCommunities,
    this.isBanned = false,
    this.banReason,
    this.banExpiresAt,
    this.durationLabel,
    this.coverBannerUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: (json['uid']?.toString() ?? '').trim(),
        displayName: (json['displayName']?.toString() ?? '').trim(),
        email: (json['email']?.toString() ?? '').trim(),
        phoneNumber: (json['phoneNumber']?.toString() ?? '').trim(),
        photoURL: (json['photoURL']?.toString() ?? '').trim(),
        bio: (json['bio']?.toString() ?? '').trim(),
        interests: List<String>.from(json['interests'] ?? []),
        role: (json['role']?.toString() ?? 'user').trim(),
        createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
        updatedAt: json['updatedAt'] as Timestamp? ?? Timestamp.now(),
        mutedCommunities: List<String>.from(json['mutedCommunities'] ?? []),
        isBanned: (json['isBanned'] as bool?) ?? false,
        banReason: json['banReason'] as String?,
        banExpiresAt: json['banExpiresAt'] as Timestamp?,
        durationLabel: json['durationLabel'] as String?,
        coverBannerUrl: json['coverBannerUrl'] as String?,
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
        'mutedCommunities': mutedCommunities,
        'isBanned': isBanned,
        if (banReason != null) 'banReason': banReason,
        if (banExpiresAt != null) 'banExpiresAt': banExpiresAt,
        if (durationLabel != null) 'durationLabel': durationLabel,
        if (coverBannerUrl != null) 'coverBannerUrl': coverBannerUrl,
      };
}
