import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// A single row in the chats list, matching the "unread / read / sent by me /
/// voice / group" states from the mockup spec.
class ChatListTile extends StatelessWidget {
  const ChatListTile({super.key, required this.chat, required this.onTap});

  final Chat chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = chat.isUnread;

    String preview = chat.lastMessage;
    if (chat.kind == ChatPreviewKind.voice) {
      preview = '🎧 Mensaje de voz · 0:14';
    } else if (chat.kind == ChatPreviewKind.group) {
      preview = chat.lastMessage;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: unread ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            UserAvatar(user: chat.otherUser, size: 52),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.otherUser.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: unread ? AppColors.lavender : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (chat.lastMessageSentByMe && chat.lastMessageRead) ...[
                        const Icon(Icons.done_all, size: 15, color: AppColors.lavender),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            color: unread ? const Color(0xFFC9CBD6) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.panel,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
