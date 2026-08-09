import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/chats/chat_detail_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile/change_email_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/requests/discover_screen.dart';
import 'screens/requests/requests_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_account_screen.dart';
import 'state/auth_controller.dart';
import 'state/requests_controller.dart';
import 'widgets/app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes reachable without a session. Verification lives here because the
/// account exists but is not active yet, so there is no session to speak of.
const Set<String> _publicRoutes = {'/login', '/register', '/verify-account'};

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: authController,
  redirect: (context, state) {
    final location = state.matchedLocation;
    final isPublic = _publicRoutes.contains(location);

    switch (authController.status) {
      case AuthStatus.unknown:
        return location == '/splash' ? null : '/splash';
      case AuthStatus.unauthenticated:
        return isPublic ? null : '/login';
      case AuthStatus.authenticated:
        return isPublic || location == '/splash' ? '/chats' : null;
    }
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/login',
      // `extra` carries a one-off notice, e.g. "cuenta verificada".
      builder: (context, state) => LoginScreen(notice: state.extra as String?),
    ),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/verify-account',
      // `extra` is the email we just registered, shown for context.
      builder: (context, state) => VerifyAccountScreen(email: state.extra as String?),
    ),
    GoRoute(
      path: '/change-email',
      // Authenticated (absent from _publicRoutes) and pushed over the shell so
      // the bottom navigation stays out of the way during the flow.
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ChangeEmailScreen(),
    ),
    GoRoute(
      path: '/discover',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const DiscoverScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AnimatedBuilder(
        // Rebuilds the shell whenever the pending-request count changes.
        animation: requestsController,
        builder: (context, _) => AppShell(
          navigationShell: navigationShell,
          requestsBadgeCount: requestsController.receivedCount,
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chats',
              builder: (context, state) => const ChatsScreen(),
              routes: [
                GoRoute(
                  path: ':friendId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => ChatDetailScreen(friendId: state.pathParameters['friendId']!),
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
