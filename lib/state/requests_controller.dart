import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/friend_request.dart';
import '../services/friend_requests_service.dart';
import 'friends_controller.dart';

/// Holds both pending-request lists. Also drives the badge on the bottom bar,
/// which is why it lives above the requests screen rather than inside it.
class RequestsController extends ChangeNotifier {
  RequestsController(this._service);

  final FriendRequestsService _service;

  List<FriendRequest> _received = const [];
  List<FriendRequest> _sent = const [];

  List<FriendRequest> get received => _received;
  List<FriendRequest> get sent => _sent;

  int get receivedCount => _received.length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  String? _error;
  String? get error => _error;

  /// Ids currently being accepted or rejected, so their card can show a spinner
  /// and ignore further taps.
  final Set<String> _busyIds = {};
  bool isBusy(String requestId) => _busyIds.contains(requestId);

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Both lists in parallel: they are independent and the screen shows a
      // count for each tab up front.
      final results = await Future.wait([_service.fetchReceived(), _service.fetchSent()]);
      _received = results[0];
      _sent = results[1];
    } on Object catch (error) {
      _error = ApiClient.mapError(error).message;
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Accepts a request and refreshes the friends list, since accepting is
  /// exactly what creates a new chat row.
  ///
  /// Returns the message to show, or throws the mapped [ApiException].
  Future<String> accept(FriendRequest request) async {
    return _resolve(request, () async {
      final message = await _service.accept(request.id);
      await friendsController.load();
      return message;
    });
  }

  Future<String> reject(FriendRequest request) async {
    return _resolve(request, () => _service.reject(request.id));
  }

  /// Shared bookkeeping: mark busy, drop the row on success, always unmark.
  ///
  /// The row is removed only after the server confirms, so a failure leaves the
  /// list truthful instead of optimistically wrong.
  Future<String> _resolve(FriendRequest request, Future<String> Function() action) async {
    _busyIds.add(request.id);
    notifyListeners();
    try {
      final message = await action();
      _received = _received.where((r) => r.id != request.id).toList();
      return message;
    } finally {
      _busyIds.remove(request.id);
      notifyListeners();
    }
  }

  /// Called after sending a request so the "Enviadas" tab reflects it.
  Future<void> refreshSent() async {
    try {
      _sent = await _service.fetchSent();
      notifyListeners();
    } on Object {
      // A stale "sent" list is not worth surfacing an error for.
    }
  }

  void clear() {
    _received = const [];
    _sent = const [];
    _busyIds.clear();
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}

/// App-wide instance, wired up in `main()`.
late final RequestsController requestsController;
