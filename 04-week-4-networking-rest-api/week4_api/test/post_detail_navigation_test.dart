// Test navigasi GoRouter: `/posts` -> tap baris -> `/post/:id` -> tombol back.
//
// Ini test jalur paling penting dari refactor ini: kalau parameter `:id` tidak
// terbaca, halaman detail akan menampilkan post yang salah dan test ini gagal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/pages/post_detail_page.dart';
import 'package:week4_api/pages/post_list_page.dart';
import 'package:week4_api/router/app_router.dart';
import 'package:week4_api/router/app_routes.dart';

const _posts = [
  Post(userId: 1, id: 1, title: 'Judul Pertama', body: 'Body Pertama'),
  Post(userId: 2, id: 2, title: 'Judul Kedua', body: 'Body Kedua'),
];

void main() {
  setUp(() {
    // Router global menyimpan lokasi terakhir antar test, jadi harus
    // dikembalikan ke halaman awal sebelum setiap test. Tanpa ini test
    // berikutnya diam-diam mulai dari /post/... dan gagal membingungkan.
    appRouter.go(AppRoutePath.posts);
  });

  /// Membangun aplikasi dengan list post palsu (tanpa jaringan).
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postListProvider.overrideWith(_FakePostListNotifier.new)],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rute /posts menampilkan daftar post', (tester) async {
    await pumpApp(tester);

    expect(find.byType(PostListPage), findsOneWidget);
    expect(find.text('Judul Pertama'), findsOneWidget);
    expect(find.text('Judul Kedua'), findsOneWidget);
  });

  testWidgets('tap baris membuka /post/:id dengan post yang benar', (
    tester,
  ) async {
    await pumpApp(tester);

    // Tap baris kedua.
    await tester.tap(find.text('Judul Kedua'));
    await tester.pumpAndSettle();

    // Halaman detail muncul, membawa id dari URL.
    expect(find.byType(PostDetailPage), findsOneWidget);
    final page = tester.widget<PostDetailPage>(find.byType(PostDetailPage));
    expect(page.postId, 2, reason: 'id harus diambil dari path parameter');

    // Judul dan body LENGKAP tampil di halaman detail.
    expect(find.text('Judul Kedua'), findsOneWidget);
    expect(find.text('Body Kedua'), findsOneWidget);
    expect(find.text('Post #2'), findsOneWidget);
  });

  testWidgets('tombol back kembali ke daftar post', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Judul Pertama'));
    await tester.pumpAndSettle();
    expect(find.byType(PostDetailPage), findsOneWidget);

    // Tombol back di AppBar.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(PostListPage), findsOneWidget);
    expect(find.byType(PostDetailPage), findsNothing);
  });

  testWidgets('deep link langsung ke /post/1 tetap berfungsi', (tester) async {
    // Skenario "langsung dibuka": tidak lewat daftar, list belum dimuat.
    appRouter.go(AppRoutePath.postDetail(1));

    await pumpApp(tester);

    // Halaman detail tetap menampilkan data yang benar.
    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.text('Judul Pertama'), findsOneWidget);
    expect(find.text('Body Pertama'), findsOneWidget);
  });

  testWidgets('path tidak dikenal menampilkan halaman error, bukan crash', (
    tester,
  ) async {
    appRouter.go('/halaman-yang-tidak-ada');

    await pumpApp(tester);

    expect(find.text('Halaman tidak ditemukan'), findsOneWidget);
  });

  testWidgets('/post/abc (id bukan angka) tidak crash', (tester) async {
    // `_parseId` mengubah "abc" menjadi 0, dan halaman menampilkan
    // "tidak ditemukan" alih-alih melempar FormatException.
    appRouter.go('/post/abc');

    await pumpApp(tester);

    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.textContaining('tidak ditemukan'), findsOneWidget);
  });
}

/// Notifier palsu: mengembalikan [_posts] tanpa menyentuh jaringan.
class _FakePostListNotifier extends PostListNotifier {
  @override
  Future<List<Post>> build() async => _posts;
}
