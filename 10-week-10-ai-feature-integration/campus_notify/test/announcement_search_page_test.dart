import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_search_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _waktu = DateTime(2026, 10, 20);

Announcement _a(String id, String title) => Announcement(
  id: id,
  title: title,
  summary: 'ringkas $id',
  body: 'isi $id',
  updatedAt: _waktu,
);

final _data = [
  _a('3', 'Politeknik Negeri Malang'),
  _a('7', 'Beasiswa Semester Ganjil'),
];

Widget _harness(List<Announcement> data) => ProviderScope(
  overrides: [announcementsProvider.overrideWith((ref) => data)],
  child: const MaterialApp(home: AnnouncementSearchPage()),
);

void main() {
  testWidgets('mengetik judul menyaring daftar', (tester) async {
    await tester.pumpWidget(_harness(_data));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search-field')), 'beasiswa');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-result-7')), findsOneWidget);
    expect(find.byKey(const Key('search-result-3')), findsNothing);
  });

  testWidgets('query tanpa hasil menampilkan empty state', (tester) async {
    await tester.pumpWidget(_harness(_data));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search-field')), 'zzz');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-empty-state')), findsOneWidget);
    expect(find.textContaining('Tidak ada hasil'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('query dikosongkan menampilkan semua lagi', (tester) async {
    await tester.pumpWidget(_harness(_data));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search-field')), 'zzz');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-field')), '');
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.byKey(const Key('search-empty-state')), findsNothing);
  });

  testWidgets('kegagalan repository tetap tampil di halaman cari', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementsProvider.overrideWith(
            (ref) => Future.error(Exception('offline')),
          ),
        ],
        child: const MaterialApp(home: AnnouncementSearchPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-error')), findsOneWidget);
  });
}
