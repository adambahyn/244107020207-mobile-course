import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

/// Domain diuji murni: tanpa SQLite, Dio, atau Firebase.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> items, Failure? failure})>
  fetchAnnouncements() async {
    if (fail) {
      return (
        items: const <Announcement>[],
        failure: const LocalFailure('data contoh rusak (simulasi)'),
      );
    }
    return (items: items, failure: null);
  }
}

void main() {
  test('GetAnnouncements meneruskan daftar dari repository', () async {
    final repo = FakeAnnouncementRepository(
      items: [
        Announcement(
          id: '3',
          title: 'Politeknik Negeri Malang',
          summary: '2 pengumuman terbaru',
          body: 'Kelas Mobile pindah ke Ruang A2.',
          updatedAt: DateTime(2026, 10, 12),
        ),
      ],
    );

    final result = await GetAnnouncements(repo).call();

    expect(result.failure, isNull);
    expect(result.items.length, 1);
    expect(result.items.first.id, '3');
  });

  test('GetAnnouncements meneruskan failure tanpa melempar', () async {
    final result = await GetAnnouncements(
      FakeAnnouncementRepository(fail: true),
    ).call();

    expect(result.failure, isA<LocalFailure>());
    expect(result.items, isEmpty);
  });
}
