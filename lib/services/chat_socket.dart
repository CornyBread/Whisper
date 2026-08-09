import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/message.dart';

enum ChatSocketStatus { connecting, connected, disconnected }

/// Real-time channel for one conversation: `GET /ws/friends/{friend_id}`.
///
/// Outgoing frames are `{"content": "..."}`; incoming ones are
/// `{"type": "message", ...}`.
class ChatSocket {
  ChatSocket(this._client, this.friendId);

  final ApiClient _client;
  final String friendId;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _suspended = false;
  int _attempt = 0;

  final _messages = StreamController<ChatMessage>.broadcast();
  final _status = StreamController<ChatSocketStatus>.broadcast();

  /// Messages pushed by the server, including the echo of our own sends.
  Stream<ChatMessage> get messages => _messages.stream;
  Stream<ChatSocketStatus> get status => _status.stream;

  bool get isConnected => _socket != null;

  /// Debug-only tracing. The socket is the one path that never touches Dio, so
  /// without this a failed send leaves nothing in the log to go on.
  void _log(String message) {
    if (kDebugMode) debugPrint('[ws $friendId] $message');
  }

  Future<void> connect() async {
    if (_disposed || _suspended || _socket != null) return;
    _status.add(ChatSocketStatus.connecting);

    try {
      // `wss://` mirrors the API's https origin; the cookie has to be attached
      // by hand because WebSocket.connect bypasses Dio and its cookie jar.
      final url = '${kApiOrigin.replaceFirst('https', 'wss')}/api/ws/friends/$friendId';
      final cookie = await _client.cookieHeader();
      _log('connecting to $url (cookie: ${cookie == null ? 'NONE' : 'present'})');
      final socket = await WebSocket.connect(
        url,
        headers: {HttpHeaders.cookieHeader: ?cookie},
      );
      if (_disposed) {
        await socket.close();
        return;
      }

      _socket = socket;
      _attempt = 0;
      _log('connected');
      _status.add(ChatSocketStatus.connected);

      _subscription = socket.listen(
        _onFrame,
        onDone: () {
          // `closeCode` reports the close regardless of which side started it,
          // so this deliberately does not claim the server closed us.
          _log('closed: code=${socket.closeCode} reason=${socket.closeReason}');
          _onClosed(closeCode: socket.closeCode);
        },
        onError: (Object error) {
          _log('stream error: $error');
          _onClosed();
        },
        cancelOnError: true,
      );
    } on Object catch (error) {
      _log('connect failed: $error');
      _onClosed();
    }
  }

  void _onFrame(dynamic frame) {
    if (frame is! String) {
      _log('ignored non-text frame (${frame.runtimeType})');
      return;
    }
    _log('recv: ${frame.length > 300 ? '${frame.substring(0, 300)}…' : frame}');
    try {
      final decoded = jsonDecode(frame);
      if (decoded is! Map) return;
      final json = Map<String, dynamic>.from(decoded);

      // Tolerates both a flat frame and one wrapping the message in a field.
      final payload = json['message'] ?? json['data'] ?? json;
      if (payload is! Map) return;

      final message = ChatMessage.fromJson(Map<String, dynamic>.from(payload));
      if (message.content.isEmpty) {
        _log('frame parsed but content was empty — ignoring');
        return;
      }
      _messages.add(message);
    } on FormatException catch (error) {
      // A frame we cannot parse is not worth tearing the connection down for.
      _log('could not decode frame: $error');
    }
  }

  /// Queues a text message. Returns false when the socket is down, so the
  /// caller can mark the bubble as failed instead of pretending it was sent.
  bool send(String content) {
    final socket = _socket;
    if (socket == null) {
      _log('send skipped: socket is down');
      return false;
    }
    try {
      socket.add(jsonEncode({'content': content}));
      _log('sent text (${content.length} chars)');
      return true;
    } on Object catch (error) {
      _log('send failed: $error');
      return false;
    }
  }

  /// Sends an image as a single binary frame. Same contract as [send]: false
  /// means it never left the device.
  bool sendBytes(List<int> bytes) {
    final socket = _socket;
    if (socket == null) {
      _log('binary send skipped: socket is down');
      return false;
    }
    try {
      socket.add(bytes);
      _log('sent binary frame (${bytes.length} bytes)');
      return true;
    } on Object catch (error) {
      _log('binary send failed: $error');
      return false;
    }
  }

  /// Close codes where retrying cannot help: the server is telling us we are
  /// not welcome, so reconnecting would just loop until the screen closes.
  static const _fatalCloseCodes = {
    1008, // policy violation
    1003, // unsupported data
    4401, // convention: unauthenticated
    4403, // convention: not friends with this user
  };

  void _onClosed({int? closeCode}) {
    _subscription?.cancel();
    _subscription = null;
    _socket = null;
    if (_disposed) return;

    _status.add(ChatSocketStatus.disconnected);

    if (closeCode != null && _fatalCloseCodes.contains(closeCode)) {
      _log('not reconnecting: close code $closeCode is final');
      return;
    }
    _scheduleReconnect();
  }

  /// Backs off 1s, 2s, 4s… capped at 15s, so a server that is down does not get
  /// hammered and the phone's radio is not kept awake.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final seconds = (1 << _attempt.clamp(0, 4)).clamp(1, 15);
    _attempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), connect);
  }

  /// Drops the connection while the app is in the background. Android tears
  /// the socket down anyway, and without this the reconnect timer keeps firing
  /// against a screen nobody is looking at — burning battery and data.
  Future<void> suspend() async {
    if (_suspended) return;
    _suspended = true;
    _reconnectTimer?.cancel();
    _log('suspended (app backgrounded)');
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
    if (!_disposed) _status.add(ChatSocketStatus.disconnected);
  }

  /// Reconnects when the app comes back to the foreground.
  Future<void> resume() async {
    if (!_suspended || _disposed) return;
    _suspended = false;
    _attempt = 0;
    _log('resumed (app foregrounded)');
    await connect();
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _socket?.close();
    _socket = null;
    await _messages.close();
    await _status.close();
  }
}
