import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/friend.dart';
import '../services/friends_service.dart';

/// Holds the friends list so the chat list and the chat detail screen agree on
/// who the user is talking to without each one refetching.
class FriendsController extends ChangeNotifier {
  FriendsController(this._service);

  final FriendsService _service;

  List<Friend> _friends = const [];
  List<Friend> get friends => _friends;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Set when the last load failed; the UI offers a retry.
  String? _error;
  String? get error => _error;

  /// True before the first load resolves, so the list can show a spinner
  /// instead of a misleading "no tienes chats".
  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  Friend? byId(String id) {
    for (final friend in _friends) {
      if (friend.id == id) return friend;
    }
    return null;
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await _service.fetchFriends();
    } on Object catch (error) {
      _error = ApiClient.mapError(error).message;
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Dropped on logout so the next account never sees the previous one's list.
  void clear() {
    _friends = const [];
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}

/// App-wide instance, wired up in `main()`.
late final FriendsController friendsController;
