import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// Bukti cache-first read: daftar post tampil dari cache lebih dulu, lalu
/// di-refresh dari jaringan di background dan disimpan untuk kunjungan
/// berikutnya.
class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final lastCached = ref.watch(lastCachedAtProvider);
    final offline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post — cache-first'),
        actions: [
          IconButton(
            tooltip: 'Refresh dari jaringan',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(postsProvider.notifier).refreshNow(),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    offline ? Icons.wifi_off : Icons.cloud_sync_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offline
                          ? 'Mode offline: hanya cache yang ditampilkan'
                          : 'Cache terakhir: '
                                '${lastCached.value == null ? "belum ada" : formatTimestamp(lastCached.value!)}',
                      key: const Key('cache-status'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal: $err')),
              data: (state) => state.posts.isEmpty
                  ? const Center(
                      key: Key('empty-posts'),
                      child: Text(
                        'Cache kosong. Sambungkan internet lalu refresh.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.posts.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final post = state.posts[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${post.id}')),
                          title: Text(post.title, maxLines: 2),
                          subtitle: Text('user ${post.userId}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
