import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/prefs.dart';
import '../data/providers.dart';
import '../router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Catat "terakhir dibuka" tanpa menahan startup: fire-and-forget.
  PrefsRepository().markOpenedNow();
  runApp(const ProviderScope(child: Week5App()));
}

class Week5App extends ConsumerWidget {
  const Week5App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkAsync = ref.watch(darkModeProvider);
    return MaterialApp.router(
      title: 'Offline Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: (darkAsync.value ?? false) ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}

/// Dipakai halaman mana pun untuk membuka Detail Catatan.
void openNote(BuildContext context, int id) => context.push(AppRoutes.note(id));
