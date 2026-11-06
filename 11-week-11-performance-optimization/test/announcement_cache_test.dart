import 'package:campus_notify/features/announcements/data/datasources/announcement_local_source.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cache repository (Minggu 11)', () {
    test('baca berulang dalam TTL tidak menyentuh sumber data', () async {
      final repo = AnnouncementRepositoryImpl(
        source: const AnnouncementLocalSource(latency: Duration.zero),
      );

      final first = await repo.fetchAnnouncements();
      final second = await repo.fetchAnnouncements();

      expect(first.failure, isNull);
      expect(second.items, same(first.items));
      expect(repo.sourceReads, 1);
    });

    test('forceRefresh menembus cache', () async {
      final repo = AnnouncementRepositoryImpl(
        source: const AnnouncementLocalSource(latency: Duration.zero),
      );

      await repo.fetchAnnouncements();
      final refreshed = await repo.fetchAnnouncements(forceRefresh: true);

      expect(repo.sourceReads, 2);
      expect(refreshed.items, hasLength(400));
    });

    test('fetchPage membagi data dan menandai halaman terakhir', () async {
      final repo = AnnouncementRepositoryImpl(
        source: const AnnouncementLocalSource(latency: Duration.zero),
      );

      final page0 = await repo.fetchPage(page: 0, pageSize: 20);
      final page1 = await repo.fetchPage(page: 1, pageSize: 20);
      final last = await repo.fetchPage(page: 13, pageSize: 30);
      final beyond = await repo.fetchPage(page: 20, pageSize: 20);

      expect(page0.items, hasLength(20));
      expect(page0.hasMore, isTrue);
      expect(page1.items.first.id, isNot(page0.items.first.id));
      expect(last.items, hasLength(10));
      expect(last.hasMore, isFalse);
      expect(beyond.items, isEmpty);
      expect(beyond.hasMore, isFalse);
    });
  });
}
