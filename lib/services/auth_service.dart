import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';

/// Wraps the `/auth/*` endpoints. Every method either completes normally or
/// throws an [ApiException] already translated for the UI.
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  /// `POST /auth/local/login` — `identity` is a username *or* an email.
  ///
  /// On success the server sets the auth cookies, which the cookie jar picks
  /// up automatically, so there is nothing to return but the confirmation.
  Future<String> login({required String identity, required String password}) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/auth/local/login',
        data: {'identity': identity, 'password': password},
      );
      return ApiClient.messageOf(response.data) ?? 'Sesión iniciada.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        // 401 here means bad credentials, not an expired session.
        unauthorizedMessage: 'Usuario o contraseña incorrectos.',
      );
    }
  }

  /// `POST /auth/logout` — clears the auth cookies server-side.
  ///
  /// Local cookies are dropped even if the call fails, so the user is never
  /// stuck in a half-logged-in state.
  Future<void> logout() async {
    try {
      await _client.dio.post<void>('/auth/logout');
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    } finally {
      await _client.clearCookies();
    }
  }

  /// `POST /auth/refresh-session` — mints a new access token from the refresh
  /// cookie. Returns false when there is no usable session (401).
  Future<bool> refreshSession() => _client.refreshSession();
}
