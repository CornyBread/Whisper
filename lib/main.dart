import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/friend_requests_service.dart';
import 'services/friends_service.dart';
import 'services/user_service.dart';
import 'state/auth_controller.dart';
import 'state/friends_controller.dart';
import 'state/requests_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = await ApiClient.init();
  authController = AuthController(
    AuthService(apiClient),
    UserService(apiClient),
    apiClient,
  );
  friendsController = FriendsController(FriendsService(apiClient));
  requestsController = RequestsController(FriendRequestsService(apiClient));
  // Kicked off without awaiting: the router shows the splash while it runs.
  authController.restoreSession();

  runApp(const WhisperApp());
}

class WhisperApp extends StatelessWidget {
  const WhisperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Whisper',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
