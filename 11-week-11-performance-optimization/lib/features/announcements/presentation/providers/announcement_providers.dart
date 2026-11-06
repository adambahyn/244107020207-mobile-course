import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/announcement_local_source.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';

/// Wiring fitur announcements: data -> domain -> presentation.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(source: const AnnouncementLocalSource()),
);

final getAnnouncementsProvider = Provider<GetAnnouncements>(
  (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)),
);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  final failure = result.failure;
  if (failure != null) throw Exception(failure.message);
  return result.items;
});

/// Satu pengumuman saja. Halaman detail memakai ini supaya hanya ikut
/// dihitung ulang ketika item yang dibukanya berubah.
final announcementByIdProvider =
    Provider.family<AsyncValue<Announcement?>, String>((ref, id) {
      return ref.watch(announcementsProvider).whenData((items) {
        for (final item in items) {
          if (item.id == id) return item;
        }
        return null;
      });
    });

/// State daftar berhalaman untuk beranda: item yang sudah dimuat, apakah masih
/// ada halaman berikutnya, dan apakah halaman berikutnya sedang dimuat.
class FeedState {
  const FeedState({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Announcement> items;
  final bool hasMore;
  final bool loadingMore;

  FeedState copyWith({
    List<Announcement>? items,
    bool? hasMore,
    bool? loadingMore,
  }) => FeedState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Pagination: halaman pertama dimuat saat build, sisanya ditambahkan saat
/// pengguna mendekati dasar daftar. Hanya halaman yang terlihat yang dibangun
/// (`ListView.builder`), dan hanya halaman yang diminta yang dibaca.
class AnnouncementFeed extends AsyncNotifier<FeedState> {
  static const int pageSize = 20;

  int _nextPage = 0;

  @override
  Future<FeedState> build() async {
    _nextPage = 0;
    final first = await ref
        .watch(getAnnouncementsProvider)
        .callPage(page: 0, pageSize: pageSize);
    final failure = first.failure;
    if (failure != null) throw Exception(failure.message);
    _nextPage = 1;
    return FeedState(items: first.items, hasMore: first.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));

    final next = await ref
        .read(getAnnouncementsProvider)
        .callPage(page: _nextPage, pageSize: pageSize);

    if (next.failure != null) {
      state = AsyncData(current.copyWith(loadingMore: false, hasMore: false));
      return;
    }
    if (next.items.isNotEmpty) _nextPage++;
    state = AsyncData(
      FeedState(
        items: [...current.items, ...next.items],
        hasMore: next.hasMore,
      ),
    );
  }

  /// Pull-to-refresh: buang state, muat halaman pertama lagi.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final announcementFeedProvider =
    AsyncNotifierProvider<AnnouncementFeed, FeedState>(AnnouncementFeed.new);
