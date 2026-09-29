import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/comment_list_page.dart';
import '../pages/paged_post_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/post_list_page.dart';
import 'app_routes.dart';

/// Konfigurasi navigasi aplikasi (GoRouter).
///
/// Didefinisikan sebagai variabel global supaya bisa di-reset di test lewat
/// `appRouter.go(AppRoutePath.posts)`. **Ingat:** router global menyimpan lokasi
/// terakhir antar `testWidgets`, jadi setiap test yang bergantung pada halaman
/// awal harus mengembalikan lokasinya lebih dulu, kalau tidak test berikutnya
/// diam-diam mulai dari halaman detail.
final GoRouter appRouter = GoRouter(
  // Halaman pertama yang dibuka.
  initialLocation: AppRoutePath.comments,

  routes: [
    // ── / : daftar komentar (endpoint GET /comments?postId=) ──────────────
    GoRoute(
      path: AppRoutePath.comments,
      name: AppRouteName.comments,
      builder: (context, state) => const CommentListPage(postId: 2),
    ),

    // ── /posts : daftar post non-paged ────────────────────────────────────
    GoRoute(
      path: AppRoutePath.posts,
      name: AppRouteName.posts,
      builder: (context, state) => const PostListPage(),

      // Rute anak: /posts/post/3 (boleh juga diakses langsung dari /post/3
      // karena rute detail didefinisikan ulang di bawah pada level atas).
      routes: [
        GoRoute(
          path: 'post/:id',
          name: '${AppRouteName.postDetail}FromList',
          builder: (context, state) =>
              PostDetailPage(postId: _parseId(state.pathParameters['id'])),
        ),
      ],
    ),

    // ── /paged : daftar post dengan pagination ────────────────────────────
    GoRoute(
      path: AppRoutePath.pagedPosts,
      name: AppRouteName.pagedPosts,
      builder: (context, state) => const PagedPostPage(),
    ),

    // ── /post/:id : detail post ───────────────────────────────────────────
    // Rute level atas supaya bisa dimasuki langsung (deep link / buka dari
    // mana pun) tanpa harus lewat daftar post.
    GoRoute(
      path: AppRoutePath.postDetailPattern,
      name: AppRouteName.postDetail,
      builder: (context, state) =>
          PostDetailPage(postId: _parseId(state.pathParameters['id'])),
    ),
  ],

  // Halaman yang tampil kalau path tidak dikenal.
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wrong_location_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Path "${state.uri}" tidak dikenal.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutePath.posts),
              child: const Text('Kembali ke daftar post'),
            ),
          ],
        ),
      ),
    ),
  ),
);

/// Mengubah `:id` dari URL menjadi `int` tanpa melempar.
///
/// `state.pathParameters['id']` bertipe `String?` dan isinya belum tentu angka
/// (mis. `/post/abc`). Mengembalikan 0 untuk input tidak valid; halaman detail
/// akan menampilkan pesan "post tidak ditemukan" alih-alih crash.
int _parseId(String? raw) => int.tryParse(raw ?? '') ?? 0;
