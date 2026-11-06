import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/providers/auth_providers.dart';
import 'core/perf/perf_probe.dart';
import 'messaging/push_service.dart';
import 'router.dart';

/// Label pengukuran: `--dart-define=PERF_LABEL=before|after`.
/// Ikut tercetak di overlay dan di logcat (`PERF|<label>|...`).
const String _perfLabel = String.fromEnvironment(
  'PERF_LABEL',
  defaultValue: 'before',
);

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
      // Overlay pengukur frame: ikut di semua halaman supaya screenshot
      // perangkat memuat angka nyata, bukan tebakan.
      builder: (context, child) => Stack(
        children: [
          ?child,
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(child: PerfOverlay(label: _perfLabel)),
          ),
        ],
      ),
    );
  }
}

class _AuthTickNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}
