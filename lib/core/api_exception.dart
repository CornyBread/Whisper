/// The kinds of failure the API surfaces, mapped from the documented
/// status codes (401 / 422 / 429 / 5xx) plus client-side network errors.
enum ApiErrorKind {
  /// 401 — bad credentials, or a missing/expired/invalid session.
  unauthorized,

  /// 422 (and 400) — the payload did not pass server validation.
  validation,

  /// 409 — the username or email is already taken.
  conflict,

  /// 404 — the resource is gone, or was never the caller's to touch.
  notFound,

  /// 403 — authenticated, but not allowed to touch this resource.
  forbidden,

  /// 429 — rate limited. See [ApiException.retryAfter].
  rateLimited,

  /// 500 and any other 5xx.
  server,

  /// No connection, DNS failure, timeout, TLS error...
  network,

  /// Anything we could not classify.
  unknown,
}

/// A failed API call, already translated into something the UI can show.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final ApiErrorKind kind;

  /// User-facing message, in Spanish, safe to render directly.
  final String message;

  final int? statusCode;

  /// Per-field messages for [ApiErrorKind.validation], keyed by field name
  /// as the server names it (e.g. `identity`, `password`).
  final Map<String, String> fieldErrors;

  /// How long to wait before retrying, taken from the `Retry-After` header
  /// on a 429. Null when the server did not say.
  final Duration? retryAfter;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
