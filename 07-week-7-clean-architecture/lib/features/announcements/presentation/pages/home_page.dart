import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../messaging/push_service.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _accessMask;
  String? _tokenMask;
  String? _fcmStatus;
  String _refreshResult = '(belum dicoba)';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(authRepositoryProvider);
    final access = await repo.accessToken();
    if (mounted) setState(() => _accessMask = maskToken(access));
    _bootstrapFcm();
  }

  /// Bukti token lifecycle: getToken -> kirim ke backend -> onTokenRefresh.
  /// Endpoint nyata kampus belum ada, jadi pengiriman disimulasikan.
  Future<void> _bootstrapFcm() async {
    try {
      final granted = await requestNotificationPermission();
      final token = await initFcmToken(
        onToken: (t) async {
          if (mounted) {
            setState(() => _fcmStatus = 'token terkirim: ${maskToken(t)}');
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _tokenMask = maskToken(token);
        _fcmStatus = granted
            ? 'Izin diberikan. Terdaftar topik pengumuman-kampus.'
            : 'Izin notifikasi DITOLAK pengguna.';
      });
    } catch (e) {
      if (mounted) setState(() => _fcmStatus = 'FCM gagal: $e');
    }
  }

  Future<void> _simulateUnauthorized() async {
    final result = await ref
        .read(authStateProvider.notifier)
        .simulateUnauthorized();
    if (mounted) setState(() => _refreshResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(announcementsProvider);
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
          ...announcements.when(
            loading: () => const [Center(child: CircularProgressIndicator())],
            error: (e, _) => [Text(messageOf(e))],
            data: (items) => [
              for (final item in items) _announcementCard(item),
            ],
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
          _row('Refresh 401', _refreshResult),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            key: const Key('simulate-401-button'),
            icon: const Icon(Icons.refresh),
            label: const Text('Simulasikan 401 + refresh'),
            onPressed: _simulateUnauthorized,
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

  Widget _announcementCard(Announcement item) => Card(
    child: ListTile(
      key: Key('announcement-${item.id}'),
      leading: Icon(item.id == '3' ? Icons.school : Icons.campaign),
      title: Text(item.title),
      subtitle: Text(item.summary),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(Routes.announcementById(item.id)),
    ),
  );

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
