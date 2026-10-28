import 'package:campus_notify/features/announcements/data/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/domain/announcement.dart';
import 'package:campus_notify/features/announcements/domain/get_announcements.dart';
import 'package:campus_notify/features/announcements/presentation/announcement_search_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRepo implements AnnouncementRepository {
  FakeRepo(this.items);
  final List<Announcement> items;
  @override
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements() async =>
      (items: items, failure: null);
}

Announcement a(String id, String title) => Announcement(
      id: id, title: title, summary: 's', body: 'b', updatedAt: DateTime(2026, 1, 1));

final data = [a('1', 'Libur Semester'), a('2', 'Beasiswa Unggulan'), a('3', 'Jadwal UTS')];

ProviderContainer makeContainer() {
  final c = ProviderContainer(overrides: [
    getAnnouncementsProvider.overrideWithValue(GetAnnouncements(FakeRepo(data))),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('query cocok judul -> hasil terfilter', () async {
    final c = makeContainer();
    c.read(searchQueryProvider.notifier).set('  libur ');
    final items = await c.read(filteredAnnouncementsProvider.future);
    expect(items.map((e) => e.id), ['1']);
  });

  test('query kosong -> semua item', () async {
    final c = makeContainer();
    c.read(searchQueryProvider.notifier).set('   ');
    final items = await c.read(filteredAnnouncementsProvider.future);
    expect(items.length, 3);
  });

  testWidgets('tanpa hasil -> empty state tampil', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [getAnnouncementsProvider.overrideWithValue(GetAnnouncements(FakeRepo(data)))],
      child: const MaterialApp(home: AnnouncementSearchPage()),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak ada hasil'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
