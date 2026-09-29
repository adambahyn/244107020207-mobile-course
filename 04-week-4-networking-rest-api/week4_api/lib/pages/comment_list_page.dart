import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_provider.dart';
import '../data/models/comment.dart';

/// Halaman daftar komentar untuk satu post.
///
/// Contoh pemakaian lapisan di bawahnya:
/// - `commentListProvider(postId)` → `AsyncValue<List<Comment>>`
/// - `commentErrorMessage(err)`    → teks ramah pengguna
///
/// Perhatikan: halaman ini **tidak** tahu apa itu Dio, URL, atau `DioException`.
/// Semua detail jaringan disembunyikan oleh repository + provider.
class CommentListPage extends ConsumerWidget {
  const CommentListPage({super.key, required this.postId});

  /// ID post yang komentarnya ditampilkan.
  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `ref.watch` pada family: satu state per postId, otomatis AsyncValue.
    final commentsAsync = ref.watch(commentListProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Komentar post #$postId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            // refresh() tanpa menghapus data lama (lihat isRefreshing).
            onPressed: () =>
                ref.read(commentListProvider(postId).notifier).refresh(),
          ),
        ],
      ),
      // `when` menangani tiga kemungkinan state AsyncValue sekaligus.
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        // `err` di sini adalah objek error yang dikirim AsyncError; teksnya
        // diterjemahkan oleh commentErrorMessage (timeout / offline / 404 / 500).
        error: (err, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                Text(commentErrorMessage(err), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  // Invalidasi provider → build() dijalankan ulang.
                  onPressed: () => ref.invalidate(commentListProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        data: (comments) {
          if (comments.isEmpty) {
            return const Center(
              child: Text('Belum ada komentar untuk post ini.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(commentListProvider(postId).notifier).refresh(),
            child: ListView.separated(
              itemCount: comments.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _CommentTile(comment: comments[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Satu baris komentar. Dipisah agar mudah diuji dan di-`const`-kan.
class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(comment.id.toString())),
      title: Text(comment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(comment.body, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
