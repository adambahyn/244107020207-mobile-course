import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

/// Kerangka aplikasi: `NavigationBar` bawah untuk berpindah antar halaman
/// tingkat atas.
///
/// Kenapa di `builder:` GoRouter dan bukan `StatefulShellRoute`?
/// - Halaman-halaman ini tidak perlu mempertahankan state scroll/isi saat
///   berpindah tab, dan tidak ada state bersama yang harus hidup terus.
/// - `StatefulShellRoute` menambah kompleksitas (satu `Navigator` per cabang)
///   yang tidak sepadan untuk tiga halaman sederhana.
/// Jadi: satu `Scaffold` pembungkus, isi halaman berubah sesuai lokasi.
///
/// Bar bawah **disembunyikan** di rute `/post/:id` (dan path bersarang
/// `.../post/:id`) supaya halaman detail tampil penuh dan tombol back bawaan
/// `AppBar` jadi cara keluar yang jelas.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  /// Isi halaman dari GoRouter.
  final Widget child;

  /// Halaman yang punya tab di NavigationBar.
  static const List<({String path, String name, IconData icon})> _tabs = [
    (
      path: AppRoutePath.comments,
      name: AppRouteName.comments,
      icon: Icons.comment_outlined,
    ),
    (
      path: AppRoutePath.posts,
      name: AppRouteName.posts,
      icon: Icons.article_outlined,
    ),
    (
      path: AppRoutePath.pagedPosts,
      name: AppRouteName.pagedPosts,
      icon: Icons.view_list_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Index tab yang cocok; -1 kalau sedang di halaman detail.
    final selectedIndex = _tabs.indexWhere(
      (tab) => tab.path == AppRoutePath.comments
          ? location == AppRoutePath.comments
          : location.startsWith(tab.path),
    );

    // Halaman detail: tampilkan isi apa adanya tanpa NavigationBar.
    if (selectedIndex < 0) return child;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              label: switch (tab.name) {
                AppRouteName.comments => 'Komentar',
                AppRouteName.posts => 'Posts',
                _ => 'Paged',
              },
            ),
        ],
      ),
    );
  }
}
