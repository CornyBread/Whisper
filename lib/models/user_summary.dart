import '../core/uploads.dart';

/// A user you are not yet connected to, as returned by `GET /users`.
///
/// That endpoint already excludes yourself, your friends and anyone with a
/// pending request in either direction, so every row here is actionable.
class UserSummary {
  const UserSummary({required this.id, required this.username, this.profilePictureUrl});

  final String id;
  final String username;
  final String? profilePictureUrl;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  String? get absoluteProfilePictureUrl => resolveUploadUrl(profilePictureUrl);

  String get initials => initialsFrom(username);
}

/// One page of `GET /users`, keeping the paging cursor the server echoed back.
class UserPage {
  const UserPage({required this.users, required this.limit, required this.offset});

  final List<UserSummary> users;
  final int limit;
  final int offset;

  factory UserPage.fromJson(Map<String, dynamic> json, {required int fallbackLimit, required int fallbackOffset}) {
    final raw = json['users'];
    return UserPage(
      users: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => UserSummary.fromJson(Map<String, dynamic>.from(item)))
              .where((user) => user.id.isNotEmpty)
              .toList()
          : const [],
      limit: json['limit'] as int? ?? fallbackLimit,
      offset: json['offset'] as int? ?? fallbackOffset,
    );
  }
}
