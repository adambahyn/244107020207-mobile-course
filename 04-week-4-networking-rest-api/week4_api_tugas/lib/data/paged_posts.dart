import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

/// State daftar post berhalaman.
///
/// Semua field final + satu kelas state = tidak ada kombinasi mustahil
/// (`isLoadingMore` dan `hasMore` selalu konsisten dengan `items`).
class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isFirstLoad = true,
    this.error,
  });

  /// Post yang sudah terkumpul dari semua halaman.
  final List<Post> items;

  /// Nomor halaman terakhir yang berhasil dimuat (0 = belum ada).
  final int page;

  /// `false` bila halaman terakhir yang dimuat lebih pendek dari [pageSize].
  final bool hasMore;

  /// Sedang memuat halaman berikutnya (footer spinner).
  final bool isLoadingMore;

  /// Muat pertama belum selesai (layar penuh spinner, bukan footer).
  final bool isFirstLoad;

  /// Error terakhir. Bisa ada bersamaan dengan `items` tidak kosong
  /// (gagal memuat halaman berikutnya, data lama tetap tampil).
  final Object? error;

  /// Server menjawab sukses tetapi tidak ada satu pun post.
  bool get isEmpty => items.isEmpty && !isFirstLoad && error == null;
}

class PagedPostsNotifier extends Notifier<PagedPostsState> {
  /// Jumlah item per halaman. Halaman pendek = data habis.
  static const pageSize = 10;

  bool _loadingFirstPage = false;

  @override
  PagedPostsState build() {
    // `build()` tidak boleh async, jadi muat pertama dijadwalkan ke microtask.
    // Dipanggil sekali per container, jadi halaman 1 tidak diminta dua kali.
    scheduleMicrotask(loadFirstPage);
    return const PagedPostsState();
  }

  /// Muat halaman 1 dan reset daftar (dipakai tombol retry + pull-to-refresh).
  Future<void> loadFirstPage() async {
    // Guard: retry yang diklik berkali-kali / pull-to-refresh saat memuat
    // tidak boleh menembak server dua kali.
    if (_loadingFirstPage) return;
    _loadingFirstPage = true;
    state = const PagedPostsState();
    try {
      final items = await ref
          .read(postRepositoryProvider)
          .fetchPostsPage(page: 1, limit: pageSize);
      state = PagedPostsState(
        items: items,
        page: 1,
        hasMore: items.length == pageSize,
        isFirstLoad: false,
      );
    } catch (e) {
      state = PagedPostsState(isFirstLoad: false, error: e);
    } finally {
      _loadingFirstPage = false;
    }
  }

  /// Muat halaman berikutnya (dipanggil listener scroll).
  Future<void> loadNextPage() async {
    // Dua guard sekaligus:
    // - `isLoadingMore` menahan request ganda saat listener scroll terpanggil
    //   berkali-kali dalam satu frame (penyebab klasik data dobel).
    // - `hasMore == false` berarti server sudah habis, jangan telepon lagi.
    if (state.isLoadingMore || !state.hasMore || state.isFirstLoad) return;

    final current = state;
    // `error: null` supaya pesan gagal sebelumnya hilang saat mencoba lagi.
    state = PagedPostsState(
      items: current.items,
      page: current.page,
      hasMore: current.hasMore,
      isLoadingMore: true,
      isFirstLoad: false,
    );

    try {
      final nextPage = current.page + 1;
      final loaded = await ref
          .read(postRepositoryProvider)
          .fetchPostsPage(page: nextPage, limit: pageSize);
      state = PagedPostsState(
        items: [...current.items, ...loaded],
        page: nextPage,
        hasMore: loaded.length == pageSize,
        isFirstLoad: false,
      );
    } catch (e) {
      // Data lama dipertahankan; nomor halaman tidak maju supaya halaman yang
      // gagal itu bisa diminta ulang.
      state = PagedPostsState(
        items: current.items,
        page: current.page,
        hasMore: current.hasMore,
        isFirstLoad: false,
        error: e,
      );
    }
  }
}

final pagedPostsProvider =
    NotifierProvider<PagedPostsNotifier, PagedPostsState>(
      PagedPostsNotifier.new,
    );
