import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'routes.dart';

/// Router dibuat lewat fungsi supaya `redirect` bisa membaca status login
/// lewat [refreshListenable] + [isLoggedIn] yang di-inject dari main.
GoRouter buildRouter({
  required bool Function() isLoggedIn,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final loggedIn = isLoggedIn();
      final goingLogin = state.matchedLocation == Routes.login;
      if (!loggedIn && !goingLogin) return Routes.login;
      if (loggedIn && goingLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: Routes.announcement,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
}
