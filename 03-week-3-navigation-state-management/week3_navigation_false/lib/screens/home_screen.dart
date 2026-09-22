import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/item_provider.dart';

/// Halaman utama.
///
/// `ConsumerWidget` adalah versi StatelessWidget yang "sadar Riverpod":
/// build() menerima parameter tambahan `WidgetRef ref`, dan lewat `ref` inilah
/// widget membaca / memantau state dari provider.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ------------------------------------------------------------------
    // ref.watch(itemProvider)
    // ------------------------------------------------------------------
    // ref.watch MEMANTAU (subscribe) provider: setiap kali state provider
    // berubah (loading -> data / loading -> error), widget ini otomatis
    // di-rebuild. Perhatikan tipe hasilnya adalah AsyncValue<List<Item>>,
    // bukan List<Item> langsung.
    final AsyncValue<List<Item>> itemsAsync = ref.watch(itemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mahasiswa IT'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang data',
            // ref.invalidate memaksa provider menjalankan fetchItems() lagi.
            // Berguna untuk menguji ulang cabang `loading:` di bawah.
            onPressed: () => ref.invalidate(itemProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // ------------------------------------------------------------------
      // POLA AsyncValue.when()
      // ------------------------------------------------------------------
      // when() memecah AsyncValue menjadi 3 cabang yang semuanya wajib diisi:
      //   loading: ()                -> data belum siap
      //   error:   (error, stack)    -> terjadi exception
      //   data:    (value)           -> data siap dipakai
      // Dengan pola ini tidak ada lagi `if (isLoading) ... else ...` manual.
      body: itemsAsync.when(
        // Cabang 1: tampilkan indikator loading di tengah layar.
        loading: () => const Center(child: CircularProgressIndicator()),

        // Cabang 2: tampilkan pesan error + tombol coba lagi.
        error: (Object error, StackTrace stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(itemProvider),
        ),

        // Cabang 3: data siap -> tampilkan sebagai list yang bisa di-scroll.
        data: (List<Item> items) {
          if (items.isEmpty) {
            return const Center(child: Text('Data masih kosong.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final Item item = items[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${item.id}')),
                  title: Text(item.name),
                  subtitle: Text('${item.nim}  •  ${item.skill}'),
                  trailing: const Icon(Icons.chevron_right),
                  // ------------------------------------------------------
                  // NAVIGASI GoRouter
                  // ------------------------------------------------------
                  // context.push() berasal dari extension GoRouterHelper
                  // (package:go_router/go_router.dart). Berbeda dengan
                  // context.go(), push MENAMBAHKAN halaman baru ke atas
                  // stack, sehingga muncul tombol back & bisa di-pop.
                  //
                  // URL dikirim dengan interpolasi id:
                  //   '/detail/3' -> ditangkap route '/detail/:id'.
                  // ------------------------------------------------------
                  onTap: () => context.push('/detail/${item.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget privat untuk menampilkan state error dari AsyncValue.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
