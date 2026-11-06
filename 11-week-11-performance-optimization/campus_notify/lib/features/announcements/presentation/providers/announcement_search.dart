import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/usecases/search_announcements.dart';
import 'announcement_providers.dart';

/// State query pencarian. `autoDispose` supaya query tidak tertinggal saat
/// halaman ditutup; ketikan hanya menghitung ulang filter, bukan fetch ulang.
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider.autoDispose<SearchQuery, String>(
  SearchQuery.new,
);

final searchAnnouncementsProvider = Provider<SearchAnnouncements>(
  (ref) => const SearchAnnouncements(),
);

/// Hasil filter tetap `AsyncValue` agar status loading/error repository
/// terlihat, sementara aturan filter ada di domain. `autoDispose` di sini
/// wajib: tanpa ini provider ini terus memegang listener ke
/// `searchQueryProvider`, sehingga query tidak pernah dibuang saat halaman
/// ditutup.
final filteredAnnouncementsProvider =
    Provider.autoDispose<AsyncValue<List<Announcement>>>((ref) {
      final asyncItems = ref.watch(announcementsProvider);
      final query = ref.watch(searchQueryProvider);
      final search = ref.watch(searchAnnouncementsProvider);
      return asyncItems.whenData((items) => search(items, query));
    });
