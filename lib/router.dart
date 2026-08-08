import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/mock_data.dart';
import 'screens/chats/chat_detail_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/requests/requests_screen.dart';
import 'widgets/app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(
        navigationShell: navigationShell,
        requestsBadgeCount: mockReceivedRequests.length,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chats',
              builder: (context, state) => const ChatsScreen(),
              routes: [
                GoRoute(
                  path: ':chatId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => ChatDetailScreen(chatId: state.pathParameters['chatId']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/requests', builder: (context, state) => const RequestsScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/profile', builder: (context, state) => const EditProfileScreen())],
        ),
      ],
    ),
  ],
);
