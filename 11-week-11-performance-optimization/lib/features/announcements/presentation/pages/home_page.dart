import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../messaging/push_service.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';
import '../widgets/announcement_tile.dart';

/// Beranda. Hanya memegang ScrollController: seluruh status perangkat pindah ke
/// [_DeviceStatusSection] supaya `setState` di sana tidak membangun ulang
/// daftar pengumuman.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Ambang 400 px: halaman berikutnya diminta sebelum pengguna mencapai dasar.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(announcementFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(announcementFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            key: const Key('search-button'),
            tooltip: 'Cari pengumuman',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.search),
          ),
          IconButton(
            key: const Key('assistant-button'),
            tooltip: 'Asisten AI',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.push(Routes.assistant),
          ),
          IconButton(
            key: const Key('logout-button'),
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(announcementFeedProvider.notifier).refresh(),
        child: feed.when(
          loading: () => const Center(
            child: CircularProgressIndicator(key: Key('feed-loading')),
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [Text(messageOf(e))],
          ),
          data: (state) => ListView.builder(
            key: const Key('home-list'),
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            // itemCount = baris pengumuman + 1 footer (status perangkat).
            itemCount: state.items.length + 1,
            itemBuilder: (context, index) {
              if (index < state.items.length) {
                final item = state.items[index];
                return RepaintBoundary(
                  key: ValueKey('tile-${item.id}'),
                  child: AnnouncementTile(
                    item: item,
                    onTap: () => context.push(Routes.announcementById(item.id)),
                  ),
                );
              }
              return Column(
                children: [
                  if (state.loadingMore || state.hasMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          key: Key('feed-loading-more'),
                        ),
                      ),
                    ),
                  const _DeviceStatusSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Status perangkat (token, FCM, uji 401). State-nya lokal di sini: perubahan
/// status tidak menyentuh daftar pengumuman di atasnya.
class _DeviceStatusSection extends ConsumerStatefulWidget {
  const _DeviceStatusSection();

  @override
  ConsumerState<_DeviceStatusSection> createState() =>
      _DeviceStatusSectionState();
}

class _DeviceStatusSectionState extends ConsumerState<_DeviceStatusSection> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
