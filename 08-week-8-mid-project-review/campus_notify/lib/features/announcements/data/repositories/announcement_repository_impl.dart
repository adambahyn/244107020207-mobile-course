import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_local_source.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl({required this.source});

  final AnnouncementLocalSource source;

  @override
  Future<({List<Announcement> items, Failure? failure})>
  fetchAnnouncements() async {
    try {
      final rows = await source.readAll();
      final items = rows
          .map((row) => AnnouncementModel.fromJson(row).toEntity())
          .toList();
      return (items: items, failure: null);
    } on Object catch (e) {
      return (
        items: const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }
}
