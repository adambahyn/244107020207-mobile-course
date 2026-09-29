import 'package:flutter/material.dart';

import '../data/models/post.dart';

/// Satu baris post di dalam `ListView`.
///
/// Diekstrak dari `post_list_page.dart` dan `paged_post_page.dart` supaya:
/// - `ListView.builder` di halaman tinggal satu baris (`PostTile(post: post)`),
///   sehingga lebih pendek dan mudah dibaca;
/// - tampilan baris post punya **satu** definisi — dulu `ListTile` yang mirip
///   ditulis ulang di dua halaman dan bisa berbeda diam-diam;
/// - widget ini bisa diuji sendiri tanpa perlu membangun seluruh halaman
///   (lihat `test/post_tile_test.dart`).
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
    this.showBody = true,
  });

  /// Data post yang ditampilkan.
  final Post post;

  /// Dijalankan saat baris ditekan. `null` berarti baris tidak bisa ditekan
  /// (dipakai halaman paged yang belum punya rute detail per item).
  final VoidCallback? onTap;

  /// Menampilkan [Post.body] sebagai subtitle.
  ///
  /// Halaman daftar (non-paged) menampilkan 2 baris body; halaman paged
  /// mematikannya supaya daftar lebih padat.
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Nomor post di kiri sebagai penanda cepat.
      leading: CircleAvatar(child: Text(post.id.toString())),

      // Judul selalu satu baris dengan elipsis supaya tinggi baris seragam.
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),

      // `showBody == false` -> subtitle null, jadi tidak ada ruang terbuang.
      subtitle: showBody
          ? Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,

      // Panah kecil sebagai petunjuk bahwa baris bisa dibuka.
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right, size: 20),

      onTap: onTap,
    );
  }
}
