// ============================================================================
// StatsPage — Flutter + flutter_riverpod (Riverpod 3.x)
//
// Tiga pengujian yang diminta:
//  1. halaman ConsumerWidget + satu AsyncNotifierProvider (delay 2 detik,
//     gagal acak 30%),
//  2. UI menangani loading / error (retry) / success (ListView 3 item),
//  3. unit test untuk notifier-nya.
// ============================================================================

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global Random: disimpan sebagai variabel agar unit test bisa meng-
// override perilakunya (deterministik) lewat overrideWith pada provider.
final _random = Random();

// ---------------------------------------------------------------------------
// Notifier — AsyncNotifier<List<String>>
// ---------------------------------------------------------------------------
// AsyncNotifier menyimpan state bertipe AsyncValue<List<String>>.
// State TIDAK PERNAH dimutasi langsung (tidak ada state.add(...)), selalu
// diganti dengan objek AsyncValue baru -> immutable.
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // Delay 2 detik = simulasi request jaringan.
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi kegagalan acak 30% (1 dari 3 kali rata-rata).
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal memuat statistik dari server');
    }

    // Mengembalikan list baru; state di-set oleh framework, bukan di-mutasi.
    return <String>['Pengunjung: 1.240', 'Penjualan: 320', 'Konversi: 4,8%'];
  }

  /// Dipanggil dari tombol "Coba lagi".
  ///
  /// Menggunakan `ref.invalidateSelf()` supaya `build()` dijalankan ulang:
  /// provider langsung berpindah ke AsyncLoading, lalu AsyncData / AsyncError
  /// sesuai hasil build() berikutnya. Ini juga otomatis menghormati `mounted`,
  /// jadi tidak ada penulisan state setelah provider di-dispose.
  ///
  /// (Alternatif manual: `state = const AsyncLoading(); state = await
  /// AsyncValue.guard(build);` — tapi rawan error "Ref ... has been disposed"
  /// kalau container sudah di-dispose saat await selesai.)
  void retry() {
    ref.invalidateSelf();
  }
}

// Deklarasi provider dengan tipe eksplisit (bukan `final x = ...` tanpa tipe)
// dan nama unik — tidak ada duplikat dengan productsProvider.
final AsyncNotifierProvider<StatsNotifier, List<String>> statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);

// ---------------------------------------------------------------------------
// UI — ConsumerWidget tunggal, tanpa Consumer bertingkat
// ---------------------------------------------------------------------------
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch HANYA di dalam build -> widget rebuild saat state berubah.
    final AsyncValue<List<String>> statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      // Ketiga cabang AsyncValue ditangani, bukan hanya data.
      body: statsAsync.when(
        // 1. LOADING -> spinner
        loading: () => const Center(child: CircularProgressIndicator()),

        // 2. ERROR -> pesan + tombol retry
        error: (Object err, StackTrace stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                Text('Gagal memuat: $err', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  // ref.read di callback (bukan saat build) -> tidak memicu
                  // rebuild yang tidak perlu.
                  onPressed: () => ref.read(statsProvider.notifier).retry(),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        // 3. SUCCESS -> ListView 3 item
        data: (List<String> stats) => ListView.builder(
          itemCount: stats.length, // 3 item
          itemBuilder: (BuildContext context, int index) => ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(stats[index]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App entry: aplikasi week3_todo hanya punya SATU entry point (lib/main.dart
// dengan GoRouter). `main()`/`MyApp` milik week3_todo2 dihapus di sini agar
// tidak ada dua entry point dalam satu package.
// ---------------------------------------------------------------------------
