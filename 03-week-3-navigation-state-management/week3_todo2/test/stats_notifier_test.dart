// Unit test untuk StatsNotifier (Riverpod 3.x).
//
// Yang diuji: ketiga cabang AsyncValue (loading / error / success) plus
// perilaku retry(). Provider asli memakai `Random` + `Future.delayed` nyata,
// jadi cabang sukses/error diuji lewat override deterministik, dan cabang
// loading diuji lewat listener supaya tidak ada state loading yang
// tertinggal saat container di-dispose.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo2/stats_page.dart';

void main() {
  group('StatsNotifier', () {
    test('state awal adalah AsyncLoading sebelum build() selesai', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Baca sekali untuk memicu build(), jangan tunggu selesai.
      expect(container.read(statsProvider), isA<AsyncLoading<List<String>>>());

      // Tunggu build() selesai (sukses atau error) supaya tidak ada provider
      // yang masih loading ketika container di-dispose.
      await _settle(container);
    });

    test('success: AsyncData berisi tepat 3 item', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(_FixedStatsNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final List<String> stats = await container.read(statsProvider.future);

      expect(stats.length, 3);
      expect(stats.first, contains('Pengunjung'));
      expect(container.read(statsProvider), isA<AsyncData<List<String>>>());
    });

    test('error: build() yang melempar menjadi AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(_FailingStatsNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // Pertahankan provider tetap "didengarkan" selama error dipropagasi:
      // Future.error yang dilempar saat build harus sudah dikonsumsi sebelum
      // container di-dispose.
      final sub = container.listen<AsyncValue<List<String>>>(
        statsProvider,
        (previous, next) {},
      );
      addTearDown(sub.close);

      // Baca state langsung (bukan `.future`): provider TIDAK auto-dispose di
      // dalam ProviderContainer, jadi error yang dilempar build() sudah
      // tersimpan sebagai AsyncError pada saat ini.
      container.read(statsProvider);
      await pumpEventQueue();

      expect(container.read(statsProvider).hasError, isTrue);
      expect(container.read(statsProvider).error, isA<Exception>());
    });

    test('retry() memicu ulang build() (invalidateSelf)', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(_FixedStatsNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(statsProvider.future);

      // Selama build() ulang berjalan, isLoading == true (AsyncData lama masih
      // dipertahankan -> pola stale-while-revalidate).
      container.read(statsProvider.notifier).retry();

      final AsyncValue<List<String>> whileRetrying =
          container.read(statsProvider);
      expect(whileRetrying.isLoading, isTrue);
      expect(whileRetrying.hasValue, isTrue);

      // Selesaikan build() ulang -> kembali ke AsyncData murni.
      await container.read(statsProvider.future);
      expect(container.read(statsProvider).isLoading, isFalse);
      expect(container.read(statsProvider), isA<AsyncData<List<String>>>());
    });
  });
}

/// Menunggu build() selesai dan menelan error (provider asli bisa gagal 30%).
Future<void> _settle(ProviderContainer container) async {
  try {
    await container.read(statsProvider.future);
  } on Exception {
    // diabaikan: yang diuji tipe state, bukan nilai data.
  }
}

/// Notifier deterministik untuk uji cabang sukses (dipakai via override).
class _FixedStatsNotifier extends StatsNotifier {
  @override
  Future<List<String>> build() async =>
      <String>['Pengunjung: 1.240', 'Penjualan: 320', 'Konversi: 4,8%'];
}

/// Notifier deterministik untuk uji cabang error (dipakai via override).
class _FailingStatsNotifier extends StatsNotifier {
  @override
  Future<List<String>> build() async => throw Exception('Gagal terhubung');
}
