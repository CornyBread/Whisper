import '../core/uploads.dart';

enum RequestDirection { received, sent }

/// A pending friend request, as returned by `/friend-requests/received` and
/// `/friend-requests/sent`.
///
/// The payload carries usernames but no profile pictures, so the UI falls back
/// to initials for these rows.
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.receiverId,
    required this.receiverUsername,
    required this.direction,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String senderId;
  final String senderUsername;
  final String receiverId;
  final String receiverUsername;
  final RequestDirection direction;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// [direction] is not in the payload — it comes from which endpoint the row
  /// was read from, so the caller supplies it.
  factory FriendRequest.fromJson(Map<String, dynamic> json, RequestDirection direction) {
    return FriendRequest(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderUsername: json['senderUsername'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      receiverUsername: json['receiverUsername'] as String? ?? '',
      direction: direction,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
    );
  }

  /// The other party: whoever is not the signed-in user on this row.
  String get otherUsername =>
      direction == RequestDirection.received ? senderUsername : receiverUsername;

  String get otherId => direction == RequestDirection.received ? senderId : receiverId;

  String get initials => initialsFrom(otherUsername);
}
