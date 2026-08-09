import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/message.dart';

/// One page of conversation history, newest message first.
class MessagePage {
  const MessagePage({required this.messages, required this.limit, required this.offset});

  final List<ChatMessage> messages;
  final int limit;
  final int offset;
}

/// Wraps `GET /messages/{friend_id}`.
class MessagesService {
  MessagesService(this._client);

  final ApiClient _client;

  static const int pageSize = 50;

  /// Returns history newest-first, exactly as the API orders it — which is
  /// also the order a `reverse: true` chat list wants.
  Future<MessagePage> fetchHistory(
    String friendId, {
    int limit = pageSize,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    try {
      final response = await _client.dio.get<dynamic>(
        '/messages/$friendId',
        queryParameters: {'limit': safeLimit, 'offset': offset},
      );
      final data = ApiClient.objectOf(response.data);
      final raw = data?['messages'];
      return MessagePage(
        messages: raw is List
            ? raw
                .whereType<Map>()
                .map((json) => ChatMessage.fromJson(Map<String, dynamic>.from(json)))
                .toList()
            : const [],
        limit: data?['limit'] as int? ?? safeLimit,
        offset: data?['offset'] as int? ?? offset,
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        // 403 here is specifically "you are not friends with this user".
        forbiddenMessage: 'Ya no eres amigo de esta persona.',
      );
    }
  }
}
