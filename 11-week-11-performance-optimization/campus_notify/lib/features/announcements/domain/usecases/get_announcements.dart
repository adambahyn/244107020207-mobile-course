import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case: satu operasi bisnis, dipanggil presentation.
/// Di sini belum ada aturan tambahan; validasi/sorting ditaruh di kelas ini
/// begitu logikanya tumbuh.
class GetAnnouncements {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  Future<({List<Announcement> items, Failure? failure})> call({
    bool forceRefresh = false,
  }) => _repository.fetchAnnouncements(forceRefresh: forceRefresh);

  /// Satu halaman untuk daftar berjalan (pagination).
  Future<({List<Announcement> items, bool hasMore, Failure? failure})>
  callPage({required int page, int pageSize = 20}) =>
      _repository.fetchPage(page: page, pageSize: pageSize);
}
