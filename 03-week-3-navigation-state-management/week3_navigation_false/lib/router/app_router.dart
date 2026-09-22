import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/detail_screen.dart';
import '../screens/home_screen.dart';

/// Konfigurasi GoRouter untuk aplikasi.
///
/// GoRouter bekerja dengan konsep "route tree": setiap [GoRoute] punya `path`
/// (URL) dan `builder` yang mengubah URL tersebut menjadi sebuah Widget.
/// Router ini adalah objek global (`appRouter`), jadi cukup dipasang sekali
/// pada `MaterialApp.router` di main.dart.
final GoRouter appRouter = GoRouter(
  // Halaman yang dibuka pertama kali saat aplikasi dijalankan.
  initialLocation: '/',
  // Membantu saat debugging: setiap perpindahan route dicatat di console.
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // ---------------------------------------------------------------
    // ROUTE 1 : '/'
    // Halaman utama yang menampilkan daftar item dari itemProvider.
    // ---------------------------------------------------------------
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),

    // ---------------------------------------------------------------
    // ROUTE 2 : '/detail/:id'
    // Tanda titik dua (:) menandakan PATH PARAMETER, yaitu bagian URL yang
    // nilainya dinamis. Contoh URL '/detail/3' -> id = '3'.
    //
    // Cara menangkapnya: state.pathParameters['id'] (bertipe String? karena
    // parameter bisa saja tidak ada). Nilai itulah yang diteruskan ke
    // DetailScreen sebagai argumen constructor.
    // ---------------------------------------------------------------
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      builder: (BuildContext context, GoRouterState state) {
        final String? id = state.pathParameters['id'];
        return DetailScreen(id: id ?? '');
      },
    ),
  ],

  // Halaman yang muncul bila URL tidak dikenali router.
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Tidak Ditemukan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Tidak ada halaman untuk: ${state.uri}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Kembali ke Home'),
            ),
          ],
        ),
      ),
    );
  },
);
