import 'package:flutter/material.dart';

import '../core/date_format.dart';
import '../models/friend.dart';
import '../theme/app_theme.dart';
import 'remote_avatar.dart';

/// A single row in the chats list: a friend plus a preview of the last message.
class ChatListTile extends StatelessWidget {
  const ChatListTile({super.key, required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = friend.lastMessage;
    final unread = friend.unreadCount > 0;
    final showReceipt = last?.sentByMe == true && last?.read == true;

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
            RemoteAvatar(
              initials: friend.initials,
              imageUrl: friend.absoluteProfilePictureUrl,
              size: 52,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          friend.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (last?.sentAt != null)
                        Text(
                          formatChatTimestamp(last!.sentAt!),
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
                      if (showReceipt) ...[
                        const Icon(Icons.done_all, size: 15, color: AppColors.lavender),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          last?.content ?? 'Aún no se han enviado mensajes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            fontStyle: last == null ? FontStyle.italic : FontStyle.normal,
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
                            '${friend.unreadCount}',
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
