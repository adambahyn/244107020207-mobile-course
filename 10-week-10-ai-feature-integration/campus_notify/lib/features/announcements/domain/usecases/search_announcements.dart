import '../entities/announcement.dart';

/// Use case murni: aturan filter judul pengumuman.
/// Tanpa IO, tanpa Riverpod, mudah diuji — inilah yang ditaruh AI di
/// presentation layer sebelum refactor.
class SearchAnnouncements {
  const SearchAnnouncements();

  List<Announcement> call(List<Announcement> items, String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((a) => a.title.toLowerCase().contains(q)).toList();
  }
}
