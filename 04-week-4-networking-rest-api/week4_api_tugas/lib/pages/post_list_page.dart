import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/paged_posts.dart';

/// Halaman daftar post dengan infinite scroll.
///
/// Halaman ini **tidak** mengimpor Dio, tidak tahu URL, dan tidak punya
/// satu pun `try/catch`. Semua urusan jaringan ada di repository + notifier;
/// di sini hanya `ref.watch(pagedPostsProvider)` dan pemetaan state ke widget.
class PostListPage extends ConsumerStatefulWidget {
  const PostListPage({super.key});

  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  final _controller = ScrollController();

  /// Ambang deteksi: mulai memuat halaman berikutnya saat sisa scroll
  /// tersisa [threshold] piksel. Tidak menunggu sampai paling bawah supaya
  /// pengguna tidak melihat jeda kosong.
  static const threshold = 300.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      // Dipanggil puluhan kali per detik saat pengguna scroll; yang menahan
      // request ganda adalah guard di dalam `loadNextPage`.
      ref.read(pagedPostsProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    // State 1: loading pertama kali (layar penuh).
    if (state.isFirstLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // State 2: error dan belum ada data sama sekali -> pesan + tombol retry.
    if (state.items.isEmpty && state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posts')),
        body: _CenteredMessage(
          icon: Icons.cloud_off,
          message: friendlyErrorMessage(state.error),
          actionLabel: 'Coba lagi',
          onAction: () => ref.read(pagedPostsProvider.notifier).loadFirstPage(),
        ),
      );
    }

    // State 3: sukses tetapi server tidak mengirim data apa pun.
    if (state.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posts')),
        body: _CenteredMessage(
          icon: Icons.inbox_outlined,
          message: 'Belum ada data dari server.',
          actionLabel: 'Muat ulang',
          onAction: () => ref.read(pagedPostsProvider.notifier).loadFirstPage(),
        ),
      );
    }

    // State 4: sukses.
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts (${state.items.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () =>
                ref.read(pagedPostsProvider.notifier).loadFirstPage(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(pagedPostsProvider.notifier).loadFirstPage(),
        child: ListView.builder(
          controller: _controller,
          // +1 baris terakhir = footer status.
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index == state.items.length) return _Footer(state: state);
            return _PostTile(post: state.items[index]);
          },
        ),
      ),
    );
  }
}

/// Footer daftar: spinner (sedang memuat), error halaman berikutnya,
/// atau penanda bahwa semua data sudah termuat.
class _Footer extends ConsumerWidget {
  const _Footer({required this.state});

  final PagedPostsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              friendlyErrorMessage(state.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  ref.read(pagedPostsProvider.notifier).loadNextPage(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Semua data termuat.')),
      );
    }
    // Masih ada halaman berikutnya, tetapi belum diminta: beri ruang supaya
    // listener scroll punya sesuatu untuk mencapai ambang.
    return const SizedBox(height: 24);
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
