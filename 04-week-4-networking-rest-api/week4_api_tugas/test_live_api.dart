// Test TERHADAP SERVER SUNGGUHAN (butuh internet). Sengaja diletakkan di akar
// project, bukan di test/, supaya `flutter test` biasa tetap bisa dijalankan
// offline.
//
//   flutter test test_live_api.dart
//
// Tujuan: membuktikan `baseUrl` + query `_page`/`_limit` benar-benar
// menghasilkan request yang diharapkan — repository palsu di test/ tidak bisa
// membuktikan ini karena Dio-nya tidak pernah dipanggil.

import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api_tugas/data/api_client.dart';
import 'package:week4_api_tugas/data/repositories/post_repository.dart';

void main() {
  late PostRepository repo;

  setUp(() => repo = PostRepository(createDio()));

  test('halaman 1 berisi tepat 10 post dengan field lengkap', () async {
    final posts = await repo.fetchPostsPage(page: 1, limit: 10);
    expect(posts.length, 10);
    expect(posts.first.id, 1);
    expect(posts.first.userId, 1);
    expect(posts.first.title, isNotEmpty);
    expect(posts.first.body, isNotEmpty);
  });

  test('halaman 2 berisi id 11..20 (pagination server benar)', () async {
    final posts = await repo.fetchPostsPage(page: 2, limit: 10);
    expect(posts.map((p) => p.id).toList(), List.generate(10, (i) => i + 11));
  });

  test('halaman 11 kosong: penanda akhir data dari server', () async {
    final posts = await repo.fetchPostsPage(page: 11, limit: 10);
    expect(posts, isEmpty, reason: 'JSONPlaceholder punya 100 post');
  });

  test('limit 3 dihormati (bukan hanya _page)', () async {
    final posts = await repo.fetchPostsPage(page: 1, limit: 3);
    expect(posts.length, 3);
  });
}
