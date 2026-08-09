import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/message.dart';
import '../services/chat_socket.dart';
import '../services/messages_service.dart';

/// One open conversation: paginated history plus the live socket.
///
/// Created and disposed by the chat screen, so it holds no global state — two
/// chats never share one.
class ChatController extends ChangeNotifier {
  ChatController({
    required ApiClient client,
    required this.friendId,
    required this.myId,
  })  : _service = MessagesService(client),
        _socket = ChatSocket(client, friendId);

  final MessagesService _service;
  final ChatSocket _socket;
  final String friendId;

  /// Needed to tell my bubbles from theirs; null if the profile failed to load.
  final String? myId;

  /// Newest first — the order the API returns and a `reverse: true` list wants.
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  ChatSocketStatus _socketStatus = ChatSocketStatus.connecting;
  ChatSocketStatus get socketStatus => _socketStatus;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ChatSocketStatus>? _statusSub;

  /// Counts pending sends so each optimistic bubble gets a unique local id.
  int _localSeq = 0;

  Future<void> start() async {
    _messageSub = _socket.messages.listen(_onIncoming);
    _statusSub = _socket.status.listen((status) {
      _socketStatus = status;
      notifyListeners();
    });
    // History first so the screen has content while the socket handshakes.
    await loadMore();
    await _socket.connect();
  }

  /// Loads the next older page. Offset counts only server-backed messages, so
  /// optimistic bubbles never shift the window.
  Future<void> loadMore() async {
    if (_isLoadingHistory || !_hasMore) return;
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      final offset = _messages.where((m) => !m.isPending).length;
      final page = await _service.fetchHistory(friendId, offset: offset);
      final known = _messages.map((m) => m.id).toSet();
      _messages.addAll(page.messages.where((m) => !known.contains(m.id)));
      _hasMore = page.messages.length >= page.limit;
    } on Object catch (error) {
      _error = ApiClient.mapError(error).message;
    } finally {
      _isLoadingHistory = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Adds the bubble immediately and lets the server echo replace it, so
  /// typing never feels like it is waiting on the network.
  void send(String text) {
    final content = text.trim();
    if (content.isEmpty) return;

    final local = ChatMessage(
      id: 'local-${_localSeq++}',
      content: content,
      senderId: myId ?? '',
      receiverId: friendId,
      kind: MessageKind.text,
      createdAt: DateTime.now(),
      isPending: true,
    );
    _messages.insert(0, local);
    notifyListeners();

    final queued = _socket.send(content);
    if (!queued) _markFailed(local.id);
  }

  /// Sends an image as a binary frame over the same socket. The server stores
  /// it and echoes back a message whose content is the hosted URL.
  Future<void> sendImage(File file) async {
    final local = ChatMessage(
      id: 'local-${_localSeq++}',
      // Empty until the server hands back the URL; the bubble previews the file.
      content: '',
      senderId: myId ?? '',
      receiverId: friendId,
      kind: MessageKind.image,
      createdAt: DateTime.now(),
      isPending: true,
      localImagePath: file.path,
    );
    _messages.insert(0, local);
    notifyListeners();

    try {
      final bytes = await file.readAsBytes();
      if (!_socket.sendBytes(bytes)) _markFailed(local.id);
    } on Object {
      _markFailed(local.id);
    }
  }

  /// Re-sends a bubble that failed, reusing its slot rather than adding a copy.
  Future<void> retry(ChatMessage message) async {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;
    _messages[index] = message.copyWith(isPending: true, failed: false);
    notifyListeners();

    if (message.kind == MessageKind.image) {
      final path = message.localImagePath;
      if (path == null) {
        _markFailed(message.id);
        return;
      }
      try {
        final bytes = await File(path).readAsBytes();
        if (!_socket.sendBytes(bytes)) _markFailed(message.id);
      } on Object {
        _markFailed(message.id);
      }
      return;
    }

    if (!_socket.send(message.content)) _markFailed(message.id);
  }

  void _markFailed(String localId) {
    final index = _messages.indexWhere((m) => m.id == localId);
    if (index == -1) return;
    _messages[index] = _messages[index].copyWith(isPending: false, failed: true);
    notifyListeners();
  }

  void _onIncoming(ChatMessage message) {
    // Already known (a reconnect can replay), so ignore it.
    if (message.id.isNotEmpty && _messages.any((m) => m.id == message.id)) return;

    // The echo of something we just sent: swap the optimistic bubble in place
    // instead of showing it twice.
    if (message.sentBy(myId)) {
      // Text echoes match on content. An image echo cannot — its content is a
      // server URL the client never saw — so the oldest pending image wins,
      // which is correct as long as the server echoes in send order.
      final pending = message.kind == MessageKind.image
          ? _messages.lastIndexWhere((m) => m.isPending && m.kind == MessageKind.image)
          : _messages.indexWhere((m) => m.isPending && m.content == message.content);
      if (pending != -1) {
        _messages[pending] = message;
        notifyListeners();
        return;
      }
    }

    _messages.insert(0, message);
    notifyListeners();
  }

  /// Mirrors the app's lifecycle onto the socket.
  Future<void> suspend() => _socket.suspend();
  Future<void> resume() => _socket.resume();

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    _socket.dispose();
    super.dispose();
  }
}
