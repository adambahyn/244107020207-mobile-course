// Test provider + pagination dengan repository palsu. Tidak menyentuh jaringan:
// `postRepositoryProvider` di-override, jadi `dioProvider` tidak pernah dibuat.
//
// Repository palsu MENCATAT setiap nomor halaman yang diminta, jadi klaim
// "tidak ada request ganda" benar-benar diperiksa, bukan diasumsikan.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api_tugas/data/models/post.dart';
import 'package:week4_api_tugas/data/paged_posts.dart';
import 'package:week4_api_tugas/data/providers.dart';
import 'package:week4_api_tugas/data/repositories/post_repository.dart';

/// Repository palsu: menimpa method asli, jadi `Dio()` di konstruktor hanya
/// memenuhi parameter `super` dan tidak pernah dipakai menelepon.
class FakePostRepository extends PostRepository {
  FakePostRepository({this.pages = const {}, this.failOnPage}) : super(Dio());

  /// halaman -> daftar post. Halaman yang tidak ada di map = halaman kosong.
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

/// Halaman penuh (10 item) supaya `hasMore` tetap true.
List<Post> fullPage(int offset) => [
  for (var i = 0; i < 10; i++)
    Post(userId: 1, id: offset + i, title: 'Post ${offset + i}', body: 'Isi'),
];

ProviderContainer containerWith(FakePostRepository repo) => ProviderContainer(
  overrides: [postRepositoryProvider.overrideWithValue(repo)],
);

/// `build()` menjadwalkan `loadFirstPage` lewat `scheduleMicrotask`, jadi
/// halaman pertama termuat setelah event loop berputar sekali. Karena itu test
/// TIDAK memanggil `loadFirstPage()` manual — itu akan meminta halaman 1 dua
/// kali (probe: requestedPages == [1, 1, 2]).
Future<void> settleFirstLoad(ProviderContainer container) async {
  container.listen(pagedPostsProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('sukses: halaman 1 termuat sekali lewat repository palsu', () async {
    final repo = FakePostRepository(pages: {1: fullPage(1)});
    final container = containerWith(repo);
    addTearDown(container.dispose);

    await settleFirstLoad(container);

    final state = container.read(pagedPostsProvider);
    expect(repo.requestedPages, [1]);
    expect(state.items.length, 10);
    expect(state.items.first.title, 'Post 1');
    expect(state.hasMore, isTrue);
    expect(state.error, isNull);
    expect(state.isFirstLoad, isFalse);
  });

  test('scroll: data bertambah, request ganda ditahan', () async {
    final repo = FakePostRepository(
      pages: {
        1: fullPage(1),
        2: fullPage(11),
        3: [], // halaman pendek -> data habis
      },
    );
    final container = containerWith(repo);
    addTearDown(container.dispose);

    await settleFirstLoad(container);
    final notifier = container.read(pagedPostsProvider.notifier);

    // Dua panggilan TANPA await: inilah yang terjadi saat listener scroll
    // terpanggil berkali-kali dalam satu frame. Guard `isLoadingMore` harus
    // menahan yang kedua.
    await Future.wait([notifier.loadNextPage(), notifier.loadNextPage()]);
    expect(repo.requestedPages, [1, 2], reason: 'halaman 2 tidak boleh 2x');

    var state = container.read(pagedPostsProvider);
    expect(state.items.length, 20, reason: 'data bertambah, tidak menimpa');
    expect(state.items.last.id, 20);

    await notifier.loadNextPage();
    expect(repo.requestedPages, [1, 2, 3]);
    state = container.read(pagedPostsProvider);
    expect(state.hasMore, isFalse, reason: 'halaman pendek = data habis');

    // `hasMore == false` -> panggilan berikutnya tidak menembak server lagi.
    await notifier.loadNextPage();
    expect(repo.requestedPages, [1, 2, 3]);
  });

  test('empty: server balas array kosong, bukan error', () async {
    final repo = FakePostRepository(pages: {1: const []});
    final container = containerWith(repo);
    addTearDown(container.dispose);

    await settleFirstLoad(container);

    final state = container.read(pagedPostsProvider);
    expect(state.items, isEmpty);
    expect(state.error, isNull);
    expect(state.isEmpty, isTrue, reason: 'UI memakai ini untuk state empty');
    expect(state.hasMore, isFalse);
  });

  test('error: state membawa DioException supaya UI bisa retry', () async {
    final repo = FakePostRepository(failOnPage: 1);
    final container = containerWith(repo);
    addTearDown(container.dispose);

    await settleFirstLoad(container);

    final state = container.read(pagedPostsProvider);
    expect(state.error, isA<DioException>());
    expect(state.items, isEmpty);
    expect(state.isFirstLoad, isFalse, reason: 'spinner layar penuh berhenti');
  });

  test('error halaman berikutnya: 10 item lama tetap tampil', () async {
    final repo = FakePostRepository(pages: {1: fullPage(1)}, failOnPage: 2);
    final container = containerWith(repo);
    addTearDown(container.dispose);

    await settleFirstLoad(container);
    await container.read(pagedPostsProvider.notifier).loadNextPage();

    final state = container.read(pagedPostsProvider);
    expect(state.error, isA<DioException>());
    expect(state.items.length, 10, reason: 'data lama dipertahankan');
    expect(state.page, 1, reason: 'nomor halaman tidak maju saat gagal');
    expect(
      state.isLoadingMore,
      isFalse,
      reason: 'spinner footer tidak nyangkut',
    );
  });

  test('retry setelah error memuat ulang dari halaman 1', () async {
    final repo = FakePostRepository(pages: {1: fullPage(1)}, failOnPage: 1);
    final container = containerWith(repo);
    addTearDown(container.dispose);

    await settleFirstLoad(container);
    expect(container.read(pagedPostsProvider).error, isA<DioException>());

    // Skenario tombol "Coba lagi": repository berikutnya berhasil.
    final ok = FakePostRepository(pages: {1: fullPage(1)});
    final container2 = containerWith(ok);
    addTearDown(container2.dispose);
    await settleFirstLoad(container2);
    await container2.read(pagedPostsProvider.notifier).loadFirstPage();

    expect(ok.requestedPages, [1, 1], reason: 'retry = minta halaman 1 lagi');
    expect(container2.read(pagedPostsProvider).error, isNull);
    expect(container2.read(pagedPostsProvider).items.length, 10);
  });
}
