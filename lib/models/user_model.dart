class UserModel {
  final String uid;
  final String displayName;
  final String bio;
  final List<String> interests;
  final String avatarUrl;
  final String phone;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.bio = '',
    this.interests = const [],
    this.avatarUrl = '',
    this.phone = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String? ?? '',
        interests: List<String>.from(json['interests'] as List? ?? []),
        avatarUrl: json['avatarUrl'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'bio': bio,
        'interests': interests,
        'avatarUrl': avatarUrl,
        'phone': phone,
      };

  UserModel copyWith({
    String? displayName,
    String? bio,
    List<String>? interests,
    String? avatarUrl,
    String? phone,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        interests: interests ?? this.interests,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
      );
}
