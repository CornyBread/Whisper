import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/user_profile.dart';

/// Wraps the `/user*` endpoints. Every method throws an [ApiException] already
/// translated for the UI, or completes normally.
class UserService {
  UserService(this._client);

  final ApiClient _client;

  /// `GET /user` — the authenticated user's own profile.
  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _client.dio.get<dynamic>('/user');
      final data = ApiClient.objectOf(response.data);
      if (data == null) {
        throw const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'El servidor no devolvió los datos del perfil.',
        );
      }
      return UserProfile.fromJson(data);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  /// `POST /user/register` — creates the account and emails a 6-digit code.
  ///
  /// The username must be alphanumeric; the server lowercases it, so we send it
  /// lowercased already to keep the UI honest about what was created.
  Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/user/register',
        data: {
          'username': username.toLowerCase(),
          'email': email,
          'password': password,
        },
      );
      return ApiClient.messageOf(response.data) ??
          'Registro exitoso. Te enviamos un código de verificación.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        conflictMessage: 'Ese usuario o correo ya está en uso.',
      );
    }
  }

  /// `POST /user/verify-account` — activates the account with the emailed code.
  ///
  /// The docs promise 400 for a bad code, but the server actually answers 401
  /// (verified against the live API), so both are treated as "wrong code"
  /// rather than as an expired session.
  Future<String> verifyAccount(String code) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/user/verify-account',
        data: {'code': code},
      );
      return ApiClient.messageOf(response.data) ?? 'Cuenta verificada.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        unauthorizedMessage: 'El código es inválido o expiró. Solicita uno nuevo.',
        useServerBadRequestMessage: true,
      );
    }
  }

  /// `POST /user/change-email` — starts an email change by emailing a 6-digit
  /// code to the *new* address. Nothing changes until [verifyEmailChange].
  ///
  /// A 400 here means the account does not sign in with username/password
  /// (i.e. it came from an OAuth provider), which is worth saying plainly.
  Future<String> changeEmail(String newEmail) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/user/change-email',
        data: {'new_email': newEmail},
      );
      return ApiClient.messageOf(response.data) ??
          'Te enviamos un código de verificación al correo nuevo.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        badRequestMessage: 'Tu cuenta no inicia sesión con usuario y contraseña, '
            'así que el correo no se puede cambiar desde aquí.',
        conflictMessage: 'Ese correo ya está en uso.',
      );
    }
  }

  /// `POST /user/verify-email-change` — confirms the change with the code sent
  /// to the new address.
  ///
  /// Deliberately left out of the client's no-refresh list: unlike account
  /// verification this endpoint is authenticated, so a 401 may well be an
  /// expired access token. Letting the interceptor refresh and retry costs one
  /// duplicate submit when the code really is wrong, but keeps a valid code
  /// from failing just because the token aged out.
  Future<String> verifyEmailChange(String code) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/user/verify-email-change',
        data: {'code': code},
      );
      return ApiClient.messageOf(response.data) ?? 'Correo actualizado.';
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        badRequestMessage: 'El código es inválido o expiró.',
        unauthorizedMessage: 'El código es inválido o expiró.',
        conflictMessage: 'Ese correo ya está en uso.',
      );
    }
  }

  /// `PATCH /user/update-data` — multipart with an optional `new_username`
  /// and an optional `image`. Omitting the image leaves the current one.
  ///
  /// Returns the refreshed profile so callers do not have to guess what the
  /// server ended up storing (it lowercases usernames, renames uploads, ...).
  Future<UserProfile> updateData({String? newUsername, File? image}) async {
    if (newUsername == null && image == null) {
      throw const ApiException(
        kind: ApiErrorKind.validation,
        message: 'No hay cambios que guardar.',
      );
    }

    final form = FormData();
    if (newUsername != null) {
      form.fields.add(MapEntry('new_username', newUsername.toLowerCase()));
    }
    if (image != null) {
      form.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: p.basename(image.path),
            contentType: _imageMediaType(image.path),
          ),
        ),
      );
    }

    try {
      await _client.dio.patch<dynamic>('/user/update-data', data: form);
    } on DioException catch (error) {
      throw ApiClient.mapError(
        error,
        conflictMessage: 'Ese nombre de usuario ya está en uso.',
      );
    }
    return fetchProfile();
  }

  /// `DELETE /user` — deletes the account and logs the user out. Local cookies
  /// are dropped too, since the session is gone either way.
  Future<void> deleteAccount() async {
    try {
      await _client.dio.delete<void>('/user');
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    } finally {
      await _client.clearCookies();
    }
  }

  /// Multipart uploads need an explicit content type; without it the server
  /// sees `application/octet-stream` and can reject the file.
  static MediaType _imageMediaType(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.gif':
        return MediaType('image', 'gif');
      case '.heic':
        return MediaType('image', 'heic');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
