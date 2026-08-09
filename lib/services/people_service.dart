import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/user_summary.dart';

/// Wraps `GET /users`: the paginated list of people available to befriend.
class PeopleService {
  PeopleService(this._client);

  final ApiClient _client;

  /// Default page size. The endpoint caps `limit` at 100.
  static const int pageSize = 20;

  Future<UserPage> fetchUsers({int limit = pageSize, int offset = 0}) async {
    // Clamped client-side so a bad caller gets a page instead of a 422.
    final safeLimit = limit.clamp(1, 100);
    try {
      final response = await _client.dio.get<dynamic>(
        '/users',
        queryParameters: {'limit': safeLimit, 'offset': offset},
      );
      final data = ApiClient.objectOf(response.data);
      if (data == null) {
        return UserPage(users: const [], limit: safeLimit, offset: offset);
      }
      return UserPage.fromJson(data, fallbackLimit: safeLimit, fallbackOffset: offset);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
