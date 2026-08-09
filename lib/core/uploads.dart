import 'api_client.dart';

/// Where uploaded files (avatars, chat images) are served from.
///
/// The API reports them as paths like `/uploads/abc123.png`, but they are
/// mounted under the API prefix, so the file actually lives at
/// `/api/uploads/abc123.png` — verified against the live server. Taking the
/// path at face value against the origin gives a 404.
const String kUploadsBaseUrl = kApiBaseUrl;

/// Turns a server-relative upload path into an absolute URL. Returns null when
/// there is nothing to show, so callers can fall back to initials.
String? resolveUploadUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$kUploadsBaseUrl$path';
}

/// Up to two letters from a username, used as the avatar placeholder.
String initialsFrom(String username) {
  if (username.isEmpty) return '?';
  return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
}

/// Short human-readable age of a timestamp, e.g. "Hace 3 días".
String formatRelativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'Hace un momento';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 30) return 'Hace ${diff.inDays} días';
  final months = diff.inDays ~/ 30;
  if (months < 12) return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
  final years = diff.inDays ~/ 365;
  return 'Hace $years ${years == 1 ? 'año' : 'años'}';
}
