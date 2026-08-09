import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/friend_request.dart';

/// Wraps the `/friend-requests/*` endpoints plus the "send request" action,
/// which the API hangs off `/users/{id}/friend-request`.
class FriendRequestsService {
  FriendRequestsService(this._client);

  final ApiClient _client;

  /// `GET /friend-requests/received` — pending requests waiting on the user.
  Future<List<FriendRequest>> fetchReceived() =>
      _fetch('/friend-requests/received', RequestDirection.received);

  /// `GET /friend-requests/sent` — pending requests the user is waiting on.
  Future<List<FriendRequest>> fetchSent() =>
      _fetch('/friend-requests/sent', RequestDirection.sent);

  Future<List<FriendRequest>> _fetch(String path, RequestDirection direction) async {
    try {
      final response = await _client.dio.get<dynamic>(path);
      final raw = ApiClient.objectOf(response.data)?['requests'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((json) => FriendRequest.fromJson(Map<String, dynamic>.from(json), direction))
          .where((request) => request.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  /// `POST /friend-requests/{id}/accept` — only the receiver may accept.
  Future<String> accept(String requestId) => _resolve(requestId, 'accept');

  /// `POST /friend-requests/{id}/reject` — only the receiver may reject. The
  /// sender is free to try again afterwards.
  Future<String> reject(String requestId) => _resolve(requestId, 'reject');

  Future<String> _resolve(String requestId, String action) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/friend-requests/$requestId/$action',
      );
      return ApiClient.messageOf(response.data) ?? 'Solicitud actualizada.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        // 404 also covers "someone already resolved it", which is the likely
        // case when the list on screen has gone stale.
        notFoundMessage: 'Esta solicitud ya no está disponible.',
      );
    }
  }

  /// `POST /users/{id}/friend-request` — sends a request to a stranger.
  Future<String> sendTo(String userId) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/users/$userId/friend-request',
      );
      return ApiClient.messageOf(response.data) ?? 'Solicitud enviada.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        badRequestMessage: 'No puedes enviarte una solicitud a ti mismo.',
        conflictMessage: 'Ya hay una solicitud pendiente con esta persona.',
      );
    }
  }
}
