import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_search_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test pembukti temuan reviewer: state query bertahan setelah halaman
/// ditinggalkan, padahal TextField baru tampil kosong.
final _data = [
  Announcement(
    id: '3',
    title: 'Politeknik Negeri Malang',
    summary: 'ringkas',
    body: 'isi',
    updatedAt: DateTime(2026, 10, 20),
  ),
  Announcement(
    id: '7',
    title: 'Beasiswa Semester Ganjil',
    summary: 'ringkas',
    body: 'isi',
    updatedAt: DateTime(2026, 10, 20),
  ),
];

void main() {
  testWidgets('query tidak tertinggal setelah halaman dibuka ulang', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [announcementsProvider.overrideWith((ref) => _data)],
    );
    addTearDown(container.dispose);

    Future<void> pumpPage(Widget page) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: page),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpPage(const AnnouncementSearchPage());
    await tester.enterText(find.byKey(const Key('search-field')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-empty-state')), findsOneWidget);

    // Tinggalkan halaman, lalu buka lagi: pengguna melihat field kosong.
    await pumpPage(const SizedBox.shrink());
    await pumpPage(const AnnouncementSearchPage());

    final field = tester.widget<TextField>(
      find.byKey(const Key('search-field')),
    );
    expect(field.controller?.text ?? '', '');
    // Field kosong harus berarti daftar penuh, bukan empty state query lama.
    expect(find.byKey(const Key('search-empty-state')), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(2));
  });
}
