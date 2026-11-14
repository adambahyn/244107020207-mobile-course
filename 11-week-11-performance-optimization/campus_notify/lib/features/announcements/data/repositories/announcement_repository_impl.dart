import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_local_source.dart';
import '../models/announcement_model.dart';

/// Repository dengan cache di memori (stale-while-revalidate sederhana):
/// pembacaan berulang dalam [ttl] tidak menyentuh sumber data, sedangkan
/// [AnnouncementRepository.fetchAnnouncements] dengan `forceRefresh` memaksa
/// baca ulang. Ini yang menghapus request/parse berulang pada pull-to-refresh.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({
    required this.source,
    this.ttl = const Duration(seconds: 30),
  });

  final AnnouncementLocalSource source;
  final Duration ttl;

  List<Announcement>? _cache;
  DateTime? _cachedAt;

  /// Jumlah baca sumber data yang benar-benar terjadi (dipakai test).
  int sourceReads = 0;

  bool get _cacheFresh {
    final at = _cachedAt;
    return _cache != null && at != null && DateTime.now().difference(at) < ttl;
  }

  @override
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cacheFresh) {
      return (items: _cache!, failure: null);
    }
    try {
      sourceReads++;
      final rows = await source.readAll();
      final items = List<Announcement>.unmodifiable(
        rows.map((row) => AnnouncementModel.fromJson(row).toEntity()),
      );
      _cache = items;
      _cachedAt = DateTime.now();
      return (items: items, failure: null);
    } on Object catch (e) {
      // Data lama lebih berguna daripada layar kosong.
      return (
        items: _cache ?? const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({List<Announcement> items, bool hasMore, Failure? failure})>
  fetchPage({required int page, required int pageSize}) async {
    try {
      sourceReads++;
      final rows = await source.readPage(page: page, pageSize: pageSize);
      final items = List<Announcement>.unmodifiable(
        rows.map((row) => AnnouncementModel.fromJson(row).toEntity()),
      );
      return (items: items, hasMore: rows.length == pageSize, failure: null);
    } on Object catch (e) {
      return (
        items: const <Announcement>[],
        hasMore: false,
        failure: LocalFailure('Gagal memuat halaman pengumuman: $e'),
      );
    }
  }
}
