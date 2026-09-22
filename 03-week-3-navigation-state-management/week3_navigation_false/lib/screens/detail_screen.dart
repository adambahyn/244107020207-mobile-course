import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/item_provider.dart';

/// Halaman detail.
///
/// `id` di sini BUKAN hardcode, melainkan dikirim oleh GoRouter dari route
/// '/detail/:id' (lihat router/app_router.dart):
///   state.pathParameters['id']  ->  DetailScreen(id: id)
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.id});

  /// Nilai path parameter berbentuk String karena berasal dari URL.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // URL selalu String, jadi perlu dikonversi ke int untuk mencari datanya.
    final int? itemId = int.tryParse(id);

    // Provider family dipanggil dengan argumen: itemByIdProvider(itemId).
    final AsyncValue<Item> itemAsync = itemId == null
        ? AsyncValue<Item>.error(
            StateError('Parameter id "$id" bukan angka yang valid.'),
            StackTrace.current,
          )
        : ref.watch(itemByIdProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Mahasiswa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () => _goBack(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ----------------------------------------------------------
            // BUKTI PASSING PARAMETER
            // ----------------------------------------------------------
            // Nilai id yang diterima dari route ditampilkan langsung di layar.
            // Coba akses '/detail/4' -> akan tampil ID = 4.
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    const Text('ID dari parameter route'),
                    const SizedBox(height: 8),
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Route: /detail/$id'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------
            // POLA AsyncValue.when() (kali kedua, untuk data per-id)
            // ----------------------------------------------------------
            // loading -> data mahasiswa masih diambil
            // error   -> id tidak ditemukan / id bukan angka
            // data    -> tampilkan detail mahasiswa
            itemAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stackTrace) => Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.orange),
                  title: const Text('Detail tidak tersedia'),
                  subtitle: Text(error.toString()),
                ),
              ),
              data: (Item item) => Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nama'),
                      subtitle: Text(item.name),
                    ),
                    ListTile(
                      leading: const Icon(Icons.badge),
                      title: const Text('NIM'),
                      subtitle: Text(item.nim),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Bidang Keahlian'),
                      subtitle: Text(item.skill),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol kembali ke halaman sebelumnya.
            // context.pop() menghapus halaman ini dari stack (kebalikan dari
            // context.push() di HomeScreen). Bila halaman dibuka langsung
            // (deep-link) sehingga tidak ada halaman sebelumnya, kita
            // fallback ke context.go('/').
            ElevatedButton.icon(
              onPressed: () => _goBack(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Home'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Go ke Home (context.go)'),
            ),
          ],
        ),
      ),
    );
  }

  /// Pop bila ada halaman sebelumnya, kalau tidak kembali ke '/'.
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}
