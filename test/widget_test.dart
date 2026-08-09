// Basic smoke test: the app boots and lands on the login screen.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whisper/core/api_client.dart';
import 'package:whisper/main.dart';
import 'package:whisper/services/auth_service.dart';
import 'package:whisper/services/friend_requests_service.dart';
import 'package:whisper/services/friends_service.dart';
import 'package:whisper/services/user_service.dart';
import 'package:whisper/state/auth_controller.dart';
import 'package:whisper/state/friends_controller.dart';
import 'package:whisper/state/requests_controller.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('whisper_test');

    // path_provider has no implementation on the test host, so point the
    // cookie jar at a throwaway directory.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    final client = await ApiClient.init();
    // All three globals are needed: signing out clears the per-account lists,
    // so AuthController touches both during restoreSession.
    friendsController = FriendsController(FriendsService(client));
    requestsController = RequestsController(FriendRequestsService(client));
    authController = AuthController(AuthService(client), UserService(client), client);

    // Resolved here rather than inside the test body: `restoreSession` does
    // real file I/O for the cookie jar, and `testWidgets` runs in a fake-async
    // zone where that never completes. No cookies on disk means this settles
    // on "unauthenticated" without touching the network.
    await authController.restoreSession();
  });

  tearDownAll(() async => tempDir.delete(recursive: true));

  testWidgets('App boots on the login screen', (WidgetTester tester) async {
    // The router redirects the splash to /login for an unauthenticated user.
    await tester.pumpWidget(const WhisperApp());
    await tester.pumpAndSettle();

    expect(find.text('Whisper'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
