import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../services/chat_socket.dart';
import '../../state/auth_controller.dart';
import '../../state/chat_controller.dart';
import '../../state/friends_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/remote_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatController _chat;

  @override
  void initState() {
    super.initState();
    _chat = ChatController(
      client: ApiClient.instance,
      friendId: widget.friendId,
      myId: authController.profile?.id,
    )..addListener(_onChatChanged);
    _chat.start();

    _messageController.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _chat.resume();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _chat.suspend();
      case AppLifecycleState.inactive:
        // Transient (a system dialog, the app switcher): not worth dropping.
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chat.removeListener(_onChatChanged);
    _chat.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    // The chat list shows the last message, which this conversation just moved.
    friendsController.load();
    super.dispose();
  }

  void _onChatChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // The list is reversed, so its "end" is the oldest message.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _chat.loadMore();
    }
  }

  void _send() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _chat.send(text);
    _messageController.clear();
    _scrollToLatest();
  }

  /// Newest sits at offset 0 in a reversed list.
  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickAndSendImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.lavender),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.lavender),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // Downscaled before it goes out: a full-resolution phone photo is several
      // megabytes, and that travels as one WebSocket frame.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;
      await _chat.sendImage(File(picked.path));
      if (!mounted) return;
      _scrollToLatest();
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showSnack(
        error.code == 'camera_access_denied' || error.code == 'photo_access_denied'
            ? 'Necesitamos permiso para acceder a tus fotos o cámara.'
            : 'No pudimos abrir el selector de imágenes.',
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(message, style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final friend = friendsController.byId(widget.friendId);
    final myId = authController.profile?.id;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              username: friend?.username ?? 'Conversación',
              avatarUrl: friend?.absoluteProfilePictureUrl,
              initials: friend?.initials ?? '?',
              status: _chat.socketStatus,
              onBack: () => context.pop(),
            ),
            Expanded(child: _buildMessages(myId)),
            _Composer(
              controller: _messageController,
              canSend: _messageController.text.trim().isNotEmpty,
              onSend: _send,
              onAttach: _pickAndSendImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(String? myId) {
    if (!_chat.hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lavender));
    }

    final messages = _chat.messages;
    if (messages.isEmpty) {
      final error = _chat.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                error == null ? Icons.forum_outlined : Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                error ?? 'Aún no hay mensajes. Escribe el primero.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _chat.loadMore,
                  child: const Text('Reintentar', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      // Newest at the bottom without having to reverse the API's ordering.
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          if (_chat.isLoadingHistory) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.lavender),
                ),
              ),
            );
          }
          return const SizedBox(height: 8);
        }

        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment: message.sentBy(myId) ? Alignment.centerRight : Alignment.centerLeft,
            child: MessageBubble(
              message: message,
              isMine: message.sentBy(myId),
              onRetry: message.failed ? () => _chat.retry(message) : null,
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.username,
    required this.avatarUrl,
    required this.initials,
    required this.status,
    required this.onBack,
  });

  final String username;
  final String? avatarUrl;
  final String initials;
  final ChatSocketStatus status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ChatSocketStatus.connected => ('En línea', AppColors.mint),
      ChatSocketStatus.connecting => ('Conectando…', AppColors.peach),
      ChatSocketStatus.disconnected => ('Sin conexión', AppColors.rose),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
          ),
          RemoteAvatar(initials: initials, imageUrl: avatarUrl, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 5),
                    Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onAttach,
            icon: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 24),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(23)),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Mensaje',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: canSend ? onSend : null,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: canSend ? AppColors.lavender : AppColors.lavender.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.panel, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
