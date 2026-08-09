import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/friend.dart';

/// Wraps the `/friends` endpoints.
class FriendsService {
  FriendsService(this._client);

  final ApiClient _client;

  /// `GET /friends` — every accepted friend, with the last message exchanged.
  ///
  /// An absent or malformed `friends` array yields an empty list: an account
  /// with no friends should look empty, not broken.
  Future<List<Friend>> fetchFriends() async {
    try {
      final response = await _client.dio.get<dynamic>('/friends');
      final raw = ApiClient.objectOf(response.data)?['friends'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((json) => Friend.fromJson(Map<String, dynamic>.from(json)))
          .where((friend) => friend.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
