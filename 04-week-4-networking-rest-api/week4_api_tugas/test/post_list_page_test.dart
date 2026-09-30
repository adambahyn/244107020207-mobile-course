// Widget test keempat state UI (loading, error+retry, empty, success).
//
// Tetap tanpa internet: repository palsu di-override di ProviderScope.
// Ini yang membuktikan klaim README "empat state tampil" benar-benar terjadi
// di widget, bukan hanya ada di kode.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api_tugas/data/models/post.dart';
import 'package:week4_api_tugas/data/providers.dart';
import 'package:week4_api_tugas/data/repositories/post_repository.dart';
import 'package:week4_api_tugas/pages/post_list_page.dart';

class _FakeRepository extends PostRepository {
  _FakeRepository({this.pages = const {}, this.failOnPage}) : super(Dio());

  final Map<int, List<Post>> pages;
  final int? failOnPage;
  final List<int> requestedPages = [];

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    requestedPages.add(page);
    if (page == failOnPage) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return pages[page] ?? const [];
  }
}

List<Post> _fullPage(int offset) => [
  for (var i = 0; i < 10; i++)
    Post(userId: 1, id: offset + i, title: 'Judul ${offset + i}', body: 'Isi'),
];

Future<void> _pump(WidgetTester tester, _FakeRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [postRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PostListPage()),
    ),
  );
}

void main() {
  testWidgets('state loading: spinner tampil sebelum data datang', (
    tester,
  ) async {
    final repo = _FakeRepository(pages: {1: _fullPage(1)});
    await _pump(tester, repo);

    // Satu frame saja: microtask pemuatan belum selesai.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('state success: judul post tampil dan jumlah di AppBar', (
    tester,
  ) async {
    final repo = _FakeRepository(pages: {1: _fullPage(1)});
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Judul 1'), findsOneWidget);
    expect(find.text('Posts (10)'), findsOneWidget);
    expect(repo.requestedPages, [1]);
  });

  testWidgets('state empty: pesan khusus, bukan pesan error', (tester) async {
    final repo = _FakeRepository(pages: {1: const []});
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada data dari server.'), findsOneWidget);
    expect(find.textContaining('Tidak dapat terhubung'), findsNothing);
  });

  testWidgets('state error: pesan jaringan + tombol retry memuat ulang', (
    tester,
  ) async {
    final repo = _FakeRepository(failOnPage: 1);
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.textContaining('Tidak dapat terhubung'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(repo.requestedPages, [1, 1], reason: 'retry meminta halaman 1 lagi');
  });

  testWidgets('infinite scroll: data bertambah saat digulir ke bawah', (
    tester,
  ) async {
    final repo = _FakeRepository(
      pages: {1: _fullPage(1), 2: _fullPage(11), 3: const []},
    );
    await _pump(tester, repo);
    await tester.pumpAndSettle();
    expect(repo.requestedPages, [1]);

    // Gulir ke bawah melewati ambang 300 px dari dasar.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    // Pengguna berhenti di dasar daftar: halaman 2 lalu 3 (kosong) dimuat
    // sampai server kehabisan data. Itu perilaku yang diinginkan, yang penting
    // tidak ada nomor halaman yang diminta dua kali.
    expect(repo.requestedPages, [1, 2, 3]);
    expect(
      repo.requestedPages.toSet().length,
      repo.requestedPages.length,
      reason: 'tidak ada request ganda',
    );
    expect(find.text('Posts (20)'), findsOneWidget);

    // Footer penanda akhir data ada di bawah daftar; gulir sekali lagi.
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Semua data termuat.'), findsOneWidget);
  });
}
