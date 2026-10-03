import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/token_store.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _accessMask;
  String? _tokenMask;
  String? _fcmStatus;
  final int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(tokenStoreProvider);
    final access = await store.readAccess();
    if (mounted) setState(() => _accessMask = TokenStore.mask(access));
    _bootstrapFcm();
  }

  /// Bukti token lifecycle: getToken -> kirim ke backend -> onTokenRefresh.
  /// Endpoint nyata kampus belum ada, jadi pengiriman disimulasikan dan
  /// endpoint POST /devices dicatat di README.
  Future<void> _bootstrapFcm() async {
    try {
      final granted = await requestNotificationPermission();
      final token = await initFcmToken(
        onToken: (t) async {
          // await dio.post('/devices', data: {'fcm_token': t, 'platform': 'android'});
          if (mounted) {
            setState(
              () => _fcmStatus = 'token terkirim: ${TokenStore.mask(t)}',
            );
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _tokenMask = TokenStore.mask(token);
        _fcmStatus = granted
            ? 'Izin diberikan. Terdaftar topik pengumuman-kampus.'
            : 'Izin notifikasi DITOLAK pengguna.';
      });
    } catch (e) {
      if (mounted) setState(() => _fcmStatus = 'FCM gagal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            key: const Key('logout-button'),
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Politeknik Negeri Malang'),
              subtitle: const Text('2 pengumuman terbaru'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.announcementById('3')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Beasiswa Semester Ganjil'),
              subtitle: const Text('Batas pendaftaran 20 Oktober'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.announcementById('7')),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Status perangkat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _row('Access token', _accessMask ?? '(memuat…)'),
          _row('Token FCM', _tokenMask ?? '(belum ada)'),
          _row('FCM', _fcmStatus ?? '(memuat…)'),
          _row('Refresh 401', '$_refreshCount kali'),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            key: const Key('simulate-401-button'),
            icon: const Icon(Icons.refresh),
            label: const Text('Simulasikan 401 + refresh'),
            onPressed: () => ref.read(refreshCountProvider.notifier).bump(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Token selalu ditampilkan terpotong. Tidak pernah ditulis ke log '
            'maupun disimpan di SharedPreferences.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Text(
            value,
            key: Key('debug-$label'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
