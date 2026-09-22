import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/stats_page.dart';
import 'pages/todo_page.dart';

/// Route aplikasi ToDo.
///
/// `/`      -> [TodoPage]  (daftar tugas)
/// `/stats` -> [StatsPage] (statistik)
///
/// Dipakai juga oleh test lewat `MaterialApp.router` supaya navigasi bisa
/// diuji tanpa menjalankan `main()`.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const TodoPage(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsPage(),
    ),
  ],
);

/// `StatefulShellRoute` untuk NavigationBar: setiap tab punya Navigator sendiri
/// sehingga pindah tab tidak menghancurkan state halaman lain.
///
/// Dipakai bersama [AppShell] sebagai `home`.
final StatefulShellRoute appShellRoute = StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      AppShell(navigationShell: navigationShell),
  branches: <StatefulShellBranch>[
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const TodoPage(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
  ],
);

final GoRouter shellRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[appShellRoute],
);

/// Kerangka aplikasi ber-[NavigationBar] untuk berpindah antara `/` dan
/// `/stats`. Indeks tab disinkronkan dengan `navigationShell.currentIndex`,
/// jadi deep-link / `context.go('/stats')` pun memindahkan tab yang benar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) =>
              navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.list),
              label: 'Daftar',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              label: 'Statistik',
            ),
          ],
        ),
      );
}

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Week 3 - ToDo',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        routerConfig: shellRouter,
      );
}
