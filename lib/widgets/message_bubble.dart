import 'dart:io';

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../theme/app_theme.dart';

/// A single chat bubble: lavender + squared bottom-right corner when sent by
/// me, surface color + squared bottom-left corner when received.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
  });

  final ChatMessage message;
  final bool isMine;

  /// Offered only on a failed send.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMine ? 20 : 6),
      bottomRight: Radius.circular(isMine ? 6 : 20),
    );

    return Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
          // Pending bubbles are dimmed so "sent" and "sending" never look alike.
          child: Opacity(
            opacity: message.isPending ? 0.55 : 1,
            child: message.kind == MessageKind.image
                ? _ImageBubble(message: message, radius: radius)
                : _TextBubble(message: message, isMine: isMine, radius: radius),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.failed) ...[
              const Icon(Icons.error_outline, size: 13, color: AppColors.rose),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'No se envió · Reintentar',
                  style: TextStyle(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.w700),
                ),
              ),
            ] else
              Text(
                message.isPending ? 'Enviando…' : _formatTime(message.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ],
    );
  }

  static String _formatTime(DateTime? when) {
    if (when == null) return '';
    return '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message, required this.isMine, required this.radius});

  final ChatMessage message;
  final bool isMine;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: isMine ? AppColors.lavender : AppColors.surface,
        borderRadius: radius,
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: isMine ? AppColors.panel : AppColors.textPrimary,
          fontWeight: isMine ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// An image message: the API stores the file and sends back its URL.
class _ImageBubble extends StatelessWidget {
  const _ImageBubble({required this.message, required this.radius});

  final ChatMessage message;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final localPath = message.localImagePath;
    final url = message.imageUrl;

    // While uploading there is no URL yet, so preview the file being sent.
    if (localPath != null && (url == null || url.isEmpty)) {
      return ClipRRect(
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280, minWidth: 140),
          child: Image.file(File(localPath), fit: BoxFit.cover),
        ),
      );
    }

    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: radius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280, minWidth: 140),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 180,
              height: 180,
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.lavender),
            );
          },
          // A dead URL must not leave an invisible gap where a photo should be.
          errorBuilder: (context, error, stackTrace) => Container(
            width: 180,
            height: 120,
            color: AppColors.surface,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                SizedBox(height: 6),
                Text('Imagen no disponible', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
