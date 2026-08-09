import '../core/uploads.dart';

/// What a message carries. The API sends `"text"` in its sample; anything it
/// does not recognise degrades to text so an unknown kind still renders.
enum MessageKind { text, image }

/// A single chat message from `GET /messages/{friend_id}` or a WebSocket frame.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.kind,
    this.createdAt,
    this.isPending = false,
    this.failed = false,
    this.localImagePath,
  });

  final String id;

  /// Message text, or the image URL when [kind] is [MessageKind.image].
  final String content;

  final String senderId;
  final String receiverId;
  final MessageKind kind;
  final DateTime? createdAt;

  /// True for a locally-added message still waiting on the server echo, so the
  /// bubble can render greyed out instead of appearing already delivered.
  final bool isPending;

  /// True when the send failed and the bubble should offer a retry.
  final bool failed;

  /// Set only on an outgoing image still in flight. The bubble previews this
  /// file until the server echoes the message back with its hosted URL, and a
  /// retry re-reads the bytes from here.
  final String? localImagePath;

  bool sentBy(String? userId) => userId != null && senderId == userId;

  /// Absolute URL for an image message.
  String? get imageUrl => kind == MessageKind.image ? resolveUploadUrl(content) : null;

  /// Accepts both payload dialects the API speaks. `GET /messages` returns
  /// camelCase with the body under `content`; WebSocket frames return
  /// snake_case and put an image's path under `url` instead — verified against
  /// the live server, so both spellings are read for every field.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] ?? json['url'] ?? json['imageUrl'])?.toString() ?? '';
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: content,
      senderId: json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? json['receiver_id']?.toString() ?? '',
      kind: _kindFrom(json, content),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  /// Resolves the message kind from `type`, which both dialects carry as
  /// `"text"` or `"image"`. Anything unrecognised falls back to inspecting the
  /// content so an unknown kind still renders as something.
  static MessageKind _kindFrom(Map<String, dynamic> json, String content) {
    final raw = (json['type'] ?? json['messageType'] ?? json['message_type'])?.toString();
    if (raw == 'image') return MessageKind.image;
    if (raw == 'text') return MessageKind.text;
    return _looksLikeImage(content) ? MessageKind.image : MessageKind.text;
  }

  static bool _looksLikeImage(String content) {
    if (!content.startsWith('/') && !content.startsWith('http')) return false;
    final path = content.split('?').first.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  ChatMessage copyWith({String? id, bool? isPending, bool? failed, DateTime? createdAt}) {
    return ChatMessage(
      id: id ?? this.id,
      content: content,
      senderId: senderId,
      receiverId: receiverId,
      kind: kind,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      failed: failed ?? this.failed,
      localImagePath: localImagePath,
    );
  }
}
