import 'package:flutter/material.dart';

import '../models/message.dart';
import '../theme/app_theme.dart';

/// A single chat bubble: lavender + squared bottom-right corner when sent by
/// me, surface color + squared bottom-left corner when received.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.sentByMe;
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: mine ? AppColors.lavender : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 6),
                bottomRight: Radius.circular(mine ? 6 : 20),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: mine ? AppColors.panel : AppColors.textPrimary,
                fontWeight: mine ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.time,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (mine && message.delivered) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.done_all,
                size: 15,
                color: message.read ? AppColors.lavender : AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The animated "…" typing indicator bubble.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    Widget dot(double opacity) => Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [dot(1), dot(0.6), dot(0.3)]),
    );
  }
}
