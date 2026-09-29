import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/post_detail_provider.dart';

/// Halaman detail satu post (`/post/:id`).
///
/// Menampilkan **title dan body lengkap** (tanpa `maxLines`/elipsis seperti di
/// daftar). Sumber data diatur `postDetailProvider`: dari list yang sudah
/// dimuat bila ada, atau lewat repository bila halaman ini dibuka langsung.
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  /// ID post yang ditampilkan; berasal dari `:id` di URL.
  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Post #$postId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            // invalidate -> provider dibangun ulang dan mencari ulang
            // (dari cache list atau dari server).
            onPressed: () => ref.invalidate(postDetailProvider(postId)),
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        // Error jaringan (timeout / offline / 404 / 500) -> pesan ramah pengguna
        // dari mapper bersama `network_errors.dart`.
        error: (err, stackTrace) => _ErrorView(
          message: friendlyErrorMessage(err),
          onRetry: () => ref.invalidate(postDetailProvider(postId)),
        ),

        data: (post) {
          // `null` berarti server menjawab, tetapi post benar-benar tidak ada
          // (mis. `/post/999`). Ini bukan error jaringan, jadi pesannya beda.
          if (post == null) {
            return _ErrorView(
              icon: Icons.search_off,
              message: 'Post #$postId tidak ditemukan.',
              onRetry: null,
            );
          }
          return _PostDetailBody(post: post);
        },
      ),
    );
  }
}

/// Isi halaman: title lengkap + body lengkap.
class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata kecil di atas judul.
          Row(
            children: [
              CircleAvatar(child: Text(post.id.toString())),
              const SizedBox(width: 12),
              Text(
                'Penulis: user #${post.userId}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Judul LENGKAP — tidak ada maxLines / overflow di sini.
          Text(
            post.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Body LENGKAP dengan `softWrap` agar teks panjang turun baris
          // (JSONPlaceholder mengirim body multi-baris dengan `\n`).
          SelectableText(
            post.body,
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Tampilan error / tidak ditemukan yang seragam di halaman ini.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off,
  });

  final String message;

  /// `null` berarti tidak ada tombol "Coba lagi" (kasus data memang tidak ada).
  final VoidCallback? onRetry;

  final IconData icon;

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
            if (onRetry case final retry?) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: retry, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }
}
