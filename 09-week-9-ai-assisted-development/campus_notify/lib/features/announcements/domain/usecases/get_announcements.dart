import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case: satu operasi bisnis, dipanggil presentation.
/// Di sini belum ada aturan tambahan; validasi/sorting ditaruh di kelas ini
/// begitu logikanya tumbuh.
class GetAnnouncements {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  Future<({List<Announcement> items, Failure? failure})> call() =>
      _repository.fetchAnnouncements();
}
