import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../models/chat.dart';
import '../../theme/app_theme.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/user_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = mockChats.firstWhere(
      (c) => c.id == widget.chatId,
      orElse: () => mockChats.first,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.bar,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
                  ),
                  UserAvatar(user: chat.otherUser, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat.otherUser.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 1),
                        Row(
                          children: const [
                            SizedBox(
                              width: 7,
                              height: 7,
                              child: DecoratedBox(decoration: BoxDecoration(color: AppColors.mint, shape: BoxShape.circle)),
                            ),
                            SizedBox(width: 5),
                            Text('En línea', style: TextStyle(fontSize: 12, color: AppColors.mint, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: AppColors.textSecondary),
                ],
              ),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? const Center(
                      child: Text('Aún no hay mensajes', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Hoy', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        for (final message in chat.messages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Align(
                              alignment: message.sentByMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: MessageBubble(message: message),
                            ),
                          ),
                        if (chat.kind != ChatPreviewKind.group)
                          const Align(alignment: Alignment.centerLeft, child: TypingBubble()),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: AppColors.bar,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 26),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(23)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Mensaje',
                                hintStyle: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const Icon(Icons.emoji_emotions_outlined, color: AppColors.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(23),
                    onTap: () {
                      // TODO: send the message once the endpoint is connected.
                      _messageController.clear();
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: AppColors.panel, size: 20),
                    ),
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
