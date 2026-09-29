// Test untuk `postDetailProvider` — memverifikasi KEDUA jalur pengambilan data
// yang diminta tugas:
//
//   1. "dari list yang sudah dimuat"  -> tidak ada request baru sama sekali
//   2. "via repository bila langsung dibuka" -> repository dipanggil sekali
//
// Repository palsu di bawah MENGHITUNG berapa kali `fetchPosts()` dipanggil,
// jadi klaim "tidak ada HTTP" bukan asumsi dari membaca kode — jumlah
// pemanggilannya benar-benar diperiksa.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/post_detail_provider.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';

const _posts = [
  Post(userId: 1, id: 1, title: 'Satu', body: 'Body satu'),
  Post(userId: 1, id: 2, title: 'Dua', body: 'Body dua'),
];

/// Repository palsu yang mencatat jumlah pemanggilan.
class _CountingRepository implements PostRepository {
  int fetchPostsCalls = 0;
  int fetchPostsPageCalls = 0;

  @override
  Future<List<Post>> fetchPosts() async {
    fetchPostsCalls++;
    return _posts;
  }

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    fetchPostsPageCalls++;
    return _posts;
  }
}

void main() {
  late _CountingRepository repo;

  ProviderContainer makeContainer() {
    repo = _CountingRepository();
    return ProviderContainer(
      overrides: [postRepositoryProvider.overrideWith((ref) => repo)],
    );
  }

  test(
    'jalur 1: list sudah dimuat -> detail TIDAK memanggil server lagi',
    () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      // Panaskan daftar post dulu, seperti pengguna membuka halaman /posts.
      await container.read(postListProvider.future);
      expect(repo.fetchPostsCalls, 1, reason: 'daftar dimuat sekali');

      // Sekarang buka detail post #2.
      final post = await container.read(postDetailProvider(2).future);

      expect(post, isNotNull);
      expect(post!.title, 'Dua');
      expect(post.body, 'Body dua');

      // Inilah inti klaimnya: tidak ada request tambahan.
      expect(
        repo.fetchPostsCalls,
        1,
        reason:
            'detail harus dilayani dari list yang sudah dimuat (cache), '
            'bukan memanggil repository lagi',
      );
    },
  );

  test('jalur 2: langsung dibuka -> detail memuat via repository', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // TIDAK menyentuh postListProvider lebih dulu: simulasi deep link
    // langsung ke /post/1 saat daftar belum pernah dimuat.
    final post = await container.read(postDetailProvider(1).future);

    expect(post, isNotNull);
    expect(post!.title, 'Satu');

    // Repository dipanggil tepat sekali untuk memuat daftar.
    expect(
      repo.fetchPostsCalls,
      1,
      reason: 'daftar harus diambil dari server karena cache kosong',
    );
  });

  test('setelah deep link, membuka detail lain juga dari cache', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // Deep link pertama memuat daftar.
    await container.read(postDetailProvider(1).future);
    expect(repo.fetchPostsCalls, 1);

    // Detail kedua masuk lewat rute yang sama; datanya sudah ada di cache.
    final second = await container.read(postDetailProvider(2).future);
    expect(second!.title, 'Dua');
    expect(
      repo.fetchPostsCalls,
      1,
      reason: 'daftar tidak boleh dimuat ulang untuk post berikutnya',
    );
  });

  test('postId tidak ada di server -> null, bukan error', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // Post #999 tidak ada di data palsu; halaman detail akan menampilkan
    // "tidak ditemukan" (bukan pesan error jaringan).
    final post = await container.read(postDetailProvider(999).future);

    expect(post, isNull);
  });

  test('postId tidak valid (0) -> null tanpa menyentuh repository', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // Dari `/post/abc`, `_parseId` menghasilkan 0.
    final post = await container.read(postDetailProvider(0).future);

    expect(post, isNull);
    expect(
      repo.fetchPostsCalls,
      0,
      reason: 'id tidak valid tidak boleh menembak jaringan',
    );
  });
}
