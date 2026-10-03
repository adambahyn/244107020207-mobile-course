import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  registerBackgroundHandler();
  await initLocalNotifications();
  runApp(const ProviderScope(child: CampusNotifyApp()));
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  late final GoRouter _router;

  /// Notifier kosong: memicu redirect router saat status login berubah.
  final _authTick = _AuthTickNotifier();

  @override
  void initState() {
    super.initState();
    _router = buildRouter(
      isLoggedIn: () => ref.read(authStateProvider).value ?? false,
      refreshListenable: _authTick,
    );

    // Deep link FCM: foreground (banner lokal diklik) & terminated.
    listenForeground(_go);
    WidgetsBinding.instance.addPostFrameCallback((_) => handleTerminated(_go));
  }

  void _go(String route) {
    if (mounted) _router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronkan redirect dengan perubahan status auth.
    ref.listen(authStateProvider, (_, _) => _authTick.tick());
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: _router,
    );
  }
}

class _AuthTickNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}
