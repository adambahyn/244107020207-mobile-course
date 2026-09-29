import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'widgets/app_shell.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Week 4 - REST API',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),

    // GoRouter menggantikan `home:` supaya navigasi berbasis URL
    // (`/`, `/posts`, `/paged`, `/post/:id`) dan deep link ke detail post
    // bisa dibuka dari mana saja, termasuk langsung ke `/post/3`.
    routerConfig: appRouter,

    // Shell dengan NavigationBar bawah, hanya tampil di halaman tingkat atas
    // (bukan di halaman detail yang punya tombol back sendiri).
    builder: (context, child) =>
        AppShell(child: child ?? const SizedBox.shrink()),
  );
}
