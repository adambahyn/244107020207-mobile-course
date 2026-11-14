import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Kontrak yang dibutuhkan domain. Sumber data (HTTP, SQLite, mock) tidak
/// pernah diketahui pemanggil.
abstract class AnnouncementRepository {
  /// Seluruh pengumuman. [forceRefresh] menembus cache (lihat implementasi),
  /// dipakai saat pengguna menarik layar untuk menyegarkan.
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements({
    bool forceRefresh = false,
  });

  /// Satu halaman pengumuman untuk daftar panjang (pagination Minggu 11).
  Future<({List<Announcement> items, bool hasMore, Failure? failure})>
  fetchPage({required int page, required int pageSize});
}
