import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Kontrak yang dibutuhkan domain. Sumber data (HTTP, SQLite, mock) tidak
/// pernah diketahui pemanggil.
abstract class AnnouncementRepository {
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements();
}
