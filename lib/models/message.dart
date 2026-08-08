/// A single chat message, either sent by the current user or received.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentByMe,
    required this.time,
    this.delivered = false,
    this.read = false,
  });

  final String id;
  final String text;
  final bool sentByMe;
  final String time;
  final bool delivered;
  final bool read;
}
