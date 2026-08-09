import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'friends_controller.dart';
import 'requests_controller.dart';

enum AuthStatus {
  /// Still checking whether the stored cookies map to a live session.
  unknown,
  authenticated,
  unauthenticated,
}

/// Single source of truth for "is there a session, and whose?". The router
/// listens to it so any change (login, logout, deleted account, expired
/// refresh) redirects on its own.
class AuthController extends ChangeNotifier {
  AuthController(this._auth, this._users, this._client) {
    _client.onSessionExpired = _handleSessionExpired;
  }

  final AuthService _auth;
  final UserService _users;
  final ApiClient _client;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  UserProfile? _profile;

  /// The signed-in user, or null while logged out / still loading.
  UserProfile? get profile => _profile;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Startup check: if cookies survived the last run, ask the server for a
  /// fresh access token instead of trusting them blindly.
  Future<void> restoreSession() async {
    if (!await _client.hasStoredSession()) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    final refreshed = await _auth.refreshSession();
    if (!refreshed) {
      await _client.clearCookies();
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    await _loadProfile();
    _setStatus(AuthStatus.authenticated);
  }

  /// Throws [ApiException] on failure so the screen can show the message.
  Future<void> login({required String identity, required String password}) async {
    await _auth.login(identity: identity, password: password);
    await _loadProfile();
    _setStatus(AuthStatus.authenticated);
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } finally {
      _profile = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Deletes the account server-side; the session dies with it.
  Future<void> deleteAccount() async {
    try {
      await _users.deleteAccount();
    } finally {
      _profile = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Pushes a username and/or profile picture change, then keeps whatever the
  /// server stored as the new local truth.
  Future<void> updateProfile({String? newUsername, File? image}) async {
    _profile = await _users.updateData(newUsername: newUsername, image: image);
    notifyListeners();
  }

  /// Re-reads `GET /user`, e.g. after coming back from a background sync.
  Future<void> refreshProfile() async {
    await _loadProfile();
    notifyListeners();
  }

  /// A failed profile fetch must not strand the user on the splash screen, so
  /// the session still counts as valid and the screens handle a null profile.
  Future<void> _loadProfile() async {
    try {
      _profile = await _users.fetchProfile();
    } on Object {
      _profile = null;
    }
  }

  void _handleSessionExpired() {
    _client.clearCookies();
    _profile = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus next) {
    // Never let one account's data leak into the next session.
    if (next == AuthStatus.unauthenticated) {
      friendsController.clear();
      requestsController.clear();
    }
    if (_status == next) {
      notifyListeners();
      return;
    }
    _status = next;
    notifyListeners();
  }
}

/// App-wide instance, wired up in `main()`.
late final AuthController authController;
