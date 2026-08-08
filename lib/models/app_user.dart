import 'package:flutter/material.dart';

/// A user of the app (the current user, or someone in a chat / request).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio = '',
    this.avatarColor = const Color(0xFFC7C2FF),
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String bio;
  final Color avatarColor;

  /// Two-letter initials used as the avatar placeholder, e.g. "Lucía Marín" -> "LM".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
