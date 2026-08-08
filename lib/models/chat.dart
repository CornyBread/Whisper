import 'app_user.dart';
import 'message.dart';

enum ChatPreviewKind { text, voice, group }

/// A row in the chat list (home screen).
class Chat {
  const Chat({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.lastMessageSentByMe = false,
    this.lastMessageRead = false,
    this.kind = ChatPreviewKind.text,
    this.messages = const [],
  });

  final String id;
  final AppUser otherUser;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool lastMessageSentByMe;
  final bool lastMessageRead;
  final ChatPreviewKind kind;
  final List<ChatMessage> messages;

  bool get isUnread => unreadCount > 0;
}
