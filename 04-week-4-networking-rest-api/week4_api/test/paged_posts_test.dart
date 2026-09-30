// Verifikasi pagination tanpa internet: `PagedPostsNotifier` diuji lewat
// repository palsu yang MENCATAT setiap nomor halaman yang diminta, jadi klaim
// "tidak ada request ganda" dan "ada indikator akhir data" benar-benar
// diperiksa, bukan diasumsikan.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';

class _FakePagedRepository extends PostRepository {
  _FakePagedRepository(this.pages, {this.failOnPage}) : super(Dio());

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

  @override
  Future<List<Post>> fetchPosts() async => const [];
}

List<Post> _page(int offset) => [
  for (var i = 0; i < 10; i++)
    Post(userId: 1, id: offset + i, title: 'Post ${offset + i}', body: 'b'),
];

/// `build()` sudah menjadwalkan `loadFirstPage` lewat `Future.microtask`,
/// jadi halaman pertama termuat setelah event loop berputar sekali.
Future<void> _settle(ProviderContainer c) async {
  c.listen(pagedPostsProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('halaman berikutnya dimuat sekali, lalu hasMore jadi false', () async {
    final repo = _FakePagedRepository({1: _page(1), 2: _page(11), 3: []});
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await _settle(container);
    expect(repo.requestedPages, [1], reason: 'build() memuat halaman 1 sekali');
    expect(container.read(pagedPostsProvider).items.length, 10);
    expect(container.read(pagedPostsProvider).hasMore, isTrue);

    // Dua panggilan beruntun TANPA await: guard `isLoadingMore` harus
    // menahan request kedua (ini penyebab klasik request ganda saat scroll).
    final notifier = container.read(pagedPostsProvider.notifier);
    await Future.wait([notifier.loadNextPage(), notifier.loadNextPage()]);
    expect(repo.requestedPages, [1, 2]);
    expect(container.read(pagedPostsProvider).items.length, 20);
    expect(container.read(pagedPostsProvider).isLoadingMore, isFalse);

    // Halaman pendek (< limit) -> data habis, indikator akhir ditampilkan UI.
    await notifier.loadNextPage();
    expect(repo.requestedPages, [1, 2, 3]);
    expect(container.read(pagedPostsProvider).hasMore, isFalse);

    // hasMore == false -> panggilan berikutnya tidak menembak jaringan lagi.
    await notifier.loadNextPage();
    expect(repo.requestedPages, [1, 2, 3]);
  });

  test(
    'error halaman berikutnya: data lama tetap ada, tidak menggandakan',
    () async {
      final repo = _FakePagedRepository({1: _page(1)}, failOnPage: 2);
      final container = ProviderContainer(
        overrides: [postRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _settle(container);
      await container.read(pagedPostsProvider.notifier).loadNextPage();

      final state = container.read(pagedPostsProvider);
      expect(state.error, isA<DioException>());
      expect(
        state.items.length,
        10,
        reason: '10 item halaman pertama dipertahankan',
      );
      expect(state.page, 1, reason: 'nomor halaman tidak maju saat gagal');
      expect(state.isLoadingMore, isFalse, reason: 'spinner tidak nyangkut');
    },
  );
}
