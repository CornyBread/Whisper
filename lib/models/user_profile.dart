import '../core/uploads.dart';

/// The authenticated user, exactly as `GET /user` returns it.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.isActive,
    this.profilePictureUrl,
    this.roles = const [],
  });

  final String id;
  final String username;
  final String email;

  /// False until the account is verified with the 6-digit email code.
  final bool isActive;

  /// Server-relative path such as `/uploads/abc123.png`, or null when the
  /// user never uploaded one.
  final String? profilePictureUrl;

  final List<String> roles;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      roles: (json['roles'] as List?)?.map((role) => role.toString()).toList() ?? const [],
    );
  }

  bool get isAdmin => roles.contains('Admin') || roles.contains('Owner');

  /// Absolute URL for [profilePictureUrl], ready to hand to [Image.network].
  String? get absoluteProfilePictureUrl => resolveUploadUrl(profilePictureUrl);

  /// Up to two letters for the avatar placeholder when there is no picture.
  String get initials => initialsFrom(username);

  UserProfile copyWith({String? username, String? profilePictureUrl}) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      email: email,
      isActive: isActive,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      roles: roles,
    );
  }
}
