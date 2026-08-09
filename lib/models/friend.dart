import '../core/uploads.dart';

/// The last message exchanged with a friend, as previewed in the chat list.
///
/// The `/friends` docs describe this but the sample payload omits it, so every
/// field is optional and several key spellings are accepted. A missing or
/// unrecognised shape degrades to "no messages yet" rather than breaking the list.
class LastMessage {
  const LastMessage({required this.content, this.sentAt, this.sentByMe, this.read});

  final String content;
  final DateTime? sentAt;

  /// Null when the payload does not say who sent it.
  final bool? sentByMe;

  /// Null when the payload does not carry read receipts.
  final bool? read;

  static LastMessage? fromJson(Object? json) {
    if (json is! Map) return null;

    final content = _firstString(json, const ['content', 'text', 'message', 'body']);
    if (content == null || content.isEmpty) return null;

    return LastMessage(
      content: content,
      sentAt: _parseDate(_firstString(json, const ['sentAt', 'sent_at', 'createdAt', 'created_at', 'timestamp'])),
      sentByMe: _firstBool(json, const ['sentByMe', 'sent_by_me', 'isMine', 'is_mine', 'fromMe']),
      read: _firstBool(json, const ['read', 'isRead', 'is_read', 'seen']),
    );
  }

  static String? _firstString(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static bool? _firstBool(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
    }
    return null;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

/// An accepted friend, as returned by `GET /friends`.
class Friend {
  const Friend({
    required this.id,
    required this.username,
    this.profilePictureUrl,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final String username;
  final String? profilePictureUrl;
  final LastMessage? lastMessage;

  /// Not in the documented payload yet; kept at 0 so the badge stays hidden
  /// until the backend exposes it.
  final int unreadCount;

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
      lastMessage: LastMessage.fromJson(json['lastMessage'] ?? json['last_message']),
      unreadCount: (json['unreadCount'] ?? json['unread_count']) as int? ?? 0,
    );
  }

  /// Absolute URL for [profilePictureUrl], ready for [Image.network].
  String? get absoluteProfilePictureUrl => resolveUploadUrl(profilePictureUrl);

  String get initials => initialsFrom(username);
}
