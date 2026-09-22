import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';

void main() {
  // ProviderScope WAJIB menjadi root widget agar seluruh provider Riverpod
  // (termasuk itemProvider) tersimpan dalam satu container global yang bisa
  // diakses oleh semua widget lewat `ref`.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp.router dipakai (bukan MaterialApp biasa) karena navigasi
    // sepenuhnya didelegasikan ke GoRouter lewat parameter `routerConfig`.
    // Semua perpindahan halaman sudah didefinisikan di app_router.dart,
    // sehingga di sini kita tidak perlu lagi memakai `home:` atau `routes:`.
    return MaterialApp.router(
      title: 'Week 3 - Navigation & State Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
