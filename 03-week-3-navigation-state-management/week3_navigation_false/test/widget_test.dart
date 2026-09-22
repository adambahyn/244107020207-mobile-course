import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_navigation/main.dart';
import 'package:week3_navigation/providers/item_provider.dart';
import 'package:week3_navigation/router/app_router.dart';

void main() {
  // appRouter adalah objek global (satu instance untuk seluruh aplikasi),
  // sehingga lokasi terakhirnya terbawa antar-test. Reset ke '/' agar tiap
  // test selalu mulai dari halaman utama.
  setUp(() => appRouter.go('/'));

  // 1) Cabang `loading:` lalu `data:` dari AsyncValue.when di HomeScreen.
  testWidgets('HomeScreen: loading -> data list mahasiswa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Kondisi awal: fetchItems() belum selesai (delay 2 detik) -> loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Majukan waktu 2 detik agar Future.delayed selesai.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Andi Pratama'), findsOneWidget);
    expect(find.text('Daftar Mahasiswa IT'), findsOneWidget);
  });

  // 2) Tap item -> GoRouter push('/detail/${item.id}') -> id tampil di detail.
  testWidgets('Tap item membuka /detail/:id dan parameter id diteruskan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Citra Dewi')); // id = 3
    await tester.pumpAndSettle();

    expect(find.text('Detail Mahasiswa'), findsOneWidget);
    expect(find.text('Route: /detail/3'), findsOneWidget);
    expect(find.text('211201233'), findsOneWidget); // data hasil lookup by id
  });

  // 3) Cabang `error:` dari AsyncValue.when.
  testWidgets('HomeScreen: cabang error tampil saat provider gagal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemProvider.overrideWith(
            (Ref ref) => Future<List<Item>>.error(Exception('Koneksi gagal')),
          ),
        ],
        child: const MyApp(),
      ),
    );
    // pumpAndSettle() saja kadang berhenti sebelum microtask error selesai,
    // jadi waktu dimajukan eksplisit beberapa kali.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Gagal memuat data'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
