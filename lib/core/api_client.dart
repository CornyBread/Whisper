import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_exception.dart';

/// Host serving the API and its uploaded files.
const String kApiOrigin = 'https://peoplefinder.kaucrow.com';

/// Base URL of the PeopleFinder API backing Whisper.
const String kApiBaseUrl = '$kApiOrigin/api';

/// Endpoints that must never trigger the automatic refresh-and-retry flow:
/// a 401 on any of them *is* the answer, not a stale session.
const Set<String> _noRefreshPaths = {
  '/auth/local/login',
  '/auth/refresh-session',
  '/auth/logout',
  // Despite the docs saying 400, a wrong or expired verification code comes
  // back as 401. Without this, a typo'd code would fire a pointless refresh
  // and then log the user out.
  '/user/verify-account',
  '/user/register',
};

/// The single [Dio] instance used by every service.
///
/// Auth is cookie based: the server sets HttpOnly access/refresh cookies on
/// login, so the whole app just needs a persistent cookie jar and every
/// request is authenticated for free.
class ApiClient {
  ApiClient._(this._dio, this._cookieJar);

  static ApiClient? _instance;

  /// The initialised client. Call [init] once during startup first.
  static ApiClient get instance {
    final client = _instance;
    if (client == null) {
      throw StateError('ApiClient.init() must be awaited before use.');
    }
    return client;
  }

  final Dio _dio;
  final PersistCookieJar _cookieJar;

  Dio get dio => _dio;

  /// Called when the session is definitively gone (refresh returned 401), so
  /// the app can bounce the user back to /login.
  VoidCallback? onSessionExpired;

  /// Creates the shared client and restores cookies persisted on disk, so a
  /// returning user is still logged in after a cold start.
  static Future<ApiClient> init() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();
    final jar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
      ignoreExpires: false,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        // We classify every status ourselves in `mapError`.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    final client = ApiClient._(dio, jar);
    dio.interceptors.add(CookieManager(jar));
    dio.interceptors.add(client._refreshInterceptor());
    if (kDebugMode) {
      // Bodies included on purpose: when the API answers 4xx/5xx the payload is
      // the only place the reason shows up. Debug builds only — never ships.
      //
      // Headers stay off: they carry the `access_token` cookie, and printing a
      // live session token into logcat means anything reading device logs (or
      // any screenshot of them) leaks the session.
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

    _instance = client;
    return client;
  }

  /// Drops every stored cookie — used on logout so no session survives.
  Future<void> clearCookies() => _cookieJar.deleteAll();

  /// Returns true when a session cookie is still on disk. Only a hint: the
  /// token may already be expired server-side, which `refresh-session` settles.
  Future<bool> hasStoredSession() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(kApiBaseUrl));
    return cookies.isNotEmpty;
  }

  /// The `Cookie` header value for API requests, or null when logged out.
  ///
  /// Needed by the WebSocket: `dart:io`'s `WebSocket.connect` does not go
  /// through Dio, so it never sees the cookie jar and has to be handed the
  /// session header explicitly.
  Future<String?> cookieHeader() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(kApiBaseUrl));
    if (cookies.isEmpty) return null;
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  // ---------------------------------------------------------------------------
  // Silent refresh
  // ---------------------------------------------------------------------------

  /// Guards against N parallel 401s each firing their own refresh call.
  Future<bool>? _pendingRefresh;

  /// Asks the server for a new access token using the refresh cookie.
  /// Concurrent callers share a single in-flight request.
  Future<bool> refreshSession() {
    return _pendingRefresh ??= _doRefresh().whenComplete(() => _pendingRefresh = null);
  }

  Future<bool> _doRefresh() async {
    try {
      await _dio.post<void>('/auth/refresh-session');
      return true;
    } on DioException {
      return false;
    }
  }

  Interceptor _refreshInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final request = error.requestOptions;
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = request.extra['__retried__'] == true;

        if (!isUnauthorized || alreadyRetried || _noRefreshPaths.contains(request.path)) {
          return handler.next(error);
        }

        final refreshed = await refreshSession();
        if (!refreshed) {
          onSessionExpired?.call();
          return handler.next(error);
        }

        try {
          request.extra['__retried__'] = true;
          final response = await _dio.fetch<dynamic>(request);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    );
  }

  /// Reads `message` out of a success payload without assuming its shape.
  ///
  /// Requests are issued as `<dynamic>` on purpose: typing them
  /// `<Map<String, dynamic>>` makes dio cast the decoded body at runtime, so a
  /// success answered with a list, a bare string, or an empty body throws and
  /// gets reported as a failed call even though the server did the work.
  static String? messageOf(Object? data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }

  /// Narrows a decoded body to a JSON object, or null when it is anything else.
  static Map<String, dynamic>? objectOf(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  /// Turns a [DioException] into an [ApiException] with a message ready to
  /// render, covering every status the API documents.
  /// [badRequestMessage] / [useServerBadRequestMessage] let a caller override
  /// the generic 400 text for endpoints where a 400 means something specific
  /// (an expired code, an account that cannot change its email) rather than a
  /// malformed payload.
  static ApiException mapError(
    Object error, {
    String? unauthorizedMessage,
    String? badRequestMessage,
    bool useServerBadRequestMessage = false,
    String? conflictMessage,
    String? notFoundMessage,
    String? forbiddenMessage,
  }) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return const ApiException(
        kind: ApiErrorKind.unknown,
        message: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          kind: ApiErrorKind.network,
          message: 'La conexión tardó demasiado. Revisa tu red e inténtalo de nuevo.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (error.error is SocketException || error.response == null) {
          return const ApiException(
            kind: ApiErrorKind.network,
            message: 'No pudimos conectar con el servidor. Revisa tu conexión.',
          );
        }
      case DioExceptionType.cancel:
        return const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'La solicitud fue cancelada.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          kind: ApiErrorKind.network,
          message: 'No pudimos verificar el certificado del servidor.',
        );
      case DioExceptionType.badResponse:
        break;
    }

    final response = error.response;
    final status = response?.statusCode;
    final body = response?.data;
    final serverMessage = _extractMessage(body);

    switch (status) {
      case 401:
        return ApiException(
          kind: ApiErrorKind.unauthorized,
          statusCode: 401,
          message: unauthorizedMessage ?? serverMessage ?? 'Tu sesión expiró. Inicia sesión de nuevo.',
        );
      case 400:
        // By default the server answers a bad payload with the raw
        // deserialization error ("missing field `identity`..."), which is for
        // us, not for the user — so it is suppressed unless the caller knows
        // this endpoint's 400 carries a real message.
        return ApiException(
          kind: ApiErrorKind.validation,
          statusCode: 400,
          message: badRequestMessage ??
              (useServerBadRequestMessage ? serverMessage : null) ??
              'Revisa los datos ingresados.',
          fieldErrors: _extractFieldErrors(body),
        );
      case 403:
        return ApiException(
          kind: ApiErrorKind.forbidden,
          statusCode: 403,
          message: forbiddenMessage ?? serverMessage ?? 'No tienes permiso para hacer esto.',
        );
      case 404:
        return ApiException(
          kind: ApiErrorKind.notFound,
          statusCode: 404,
          message: notFoundMessage ?? serverMessage ?? 'No encontramos lo que buscabas.',
        );
      case 409:
        return ApiException(
          kind: ApiErrorKind.conflict,
          statusCode: 409,
          message: conflictMessage ?? serverMessage ?? 'Esos datos ya están en uso.',
          fieldErrors: _extractFieldErrors(body),
        );
      case 422:
        final fields = _extractFieldErrors(body);
        return ApiException(
          kind: ApiErrorKind.validation,
          statusCode: 422,
          message: serverMessage ?? fields.values.firstOrNull ?? 'Revisa los datos ingresados.',
          fieldErrors: fields,
        );
      case 429:
        final retryAfter = _parseRetryAfter(response?.headers.value('retry-after'));
        return ApiException(
          kind: ApiErrorKind.rateLimited,
          statusCode: 429,
          retryAfter: retryAfter,
          message: retryAfter != null
              ? 'Demasiados intentos. Espera ${_humanize(retryAfter)} antes de volver a intentar.'
              : 'Demasiados intentos. Espera un momento antes de volver a intentar.',
        );
      default:
        if (status != null && status >= 500) {
          return ApiException(
            kind: ApiErrorKind.server,
            statusCode: status,
            message: 'El servidor tuvo un problema. Inténtalo más tarde.',
          );
        }
        return ApiException(
          kind: ApiErrorKind.unknown,
          statusCode: status,
          message: serverMessage ?? 'Ocurrió un error inesperado. Inténtalo de nuevo.',
        );
    }
  }

  /// Pulls a human message out of the body, tolerating the usual shapes
  /// (`message`, `error`, `detail`) since the docs only pin down the 200 case.
  static String? _extractMessage(Object? body) {
    if (body is String && body.trim().isNotEmpty && !body.trimLeft().startsWith('<')) {
      return body.trim();
    }
    if (body is! Map) return null;
    for (final key in const ['message', 'error', 'detail', 'msg']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Normalises 422 payloads into `{field: message}`. Handles both
  /// `{"errors": {...}}` / `{"errors": [...]}` and FastAPI-style `detail` lists.
  static Map<String, String> _extractFieldErrors(Object? body) {
    if (body is! Map) return const {};
    final result = <String, String>{};

    void addEntry(Object? field, Object? message) {
      final name = field?.toString();
      if (name == null || name.isEmpty) return;
      final text = message is List ? message.firstOrNull?.toString() : message?.toString();
      if (text == null || text.isEmpty) return;
      result.putIfAbsent(name, () => text);
    }

    final errors = body['errors'] ?? body['detail'] ?? body['fields'];
    if (errors is Map) {
      errors.forEach(addEntry);
    } else if (errors is List) {
      for (final item in errors) {
        if (item is! Map) continue;
        final loc = item['loc'];
        final field = loc is List && loc.isNotEmpty ? loc.last : (item['field'] ?? item['path']);
        addEntry(field, item['msg'] ?? item['message']);
      }
    }
    return result;
  }

  /// `Retry-After` is either a delay in seconds or an HTTP date.
  static Duration? _parseRetryAfter(String? header) {
    if (header == null || header.isEmpty) return null;
    final seconds = int.tryParse(header.trim());
    if (seconds != null) return Duration(seconds: seconds.clamp(0, 3600));
    try {
      final date = HttpDate.parse(header);
      final delta = date.difference(DateTime.now());
      return delta.isNegative ? null : delta;
    } on FormatException {
      return null;
    }
  }

  static String _humanize(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds} segundos';
    return '${duration.inMinutes} minuto${duration.inMinutes == 1 ? '' : 's'}';
  }
}
