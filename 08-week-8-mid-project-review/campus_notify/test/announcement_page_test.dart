import 'dart:async';

import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Future<List<Announcement>> Function() muat) => ProviderScope(
  overrides: [announcementsProvider.overrideWith((ref) => muat())],
  child: const MaterialApp(home: AnnouncementPage(id: '3')),
);

final _waktu = DateTime(2026, 9, 27);

Announcement _contoh(String id) => Announcement(
  id: id,
  title: 'Uji',
  summary: 'Ringkas',
  body: 'Isi pengumuman uji.',
  updatedAt: _waktu,
);

void main() {
  testWidgets('deep link saat data belum siap menampilkan loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(() => Completer<List<Announcement>>().future),
    );
    await tester.pump();

    expect(find.byKey(const Key('announcement-loading')), findsOneWidget);
    expect(find.textContaining('belum tersedia'), findsNothing);
  });

  testWidgets('id yang tidak ada memakai teks cadangan', (tester) async {
    await tester.pumpWidget(_harness(() async => [_contoh('1')]));
    await tester.pumpAndSettle();

    expect(find.textContaining('belum tersedia'), findsOneWidget);
  });

  testWidgets('id yang ada menampilkan isi dan tanggal', (tester) async {
    await tester.pumpWidget(_harness(() async => [_contoh('3')]));
    await tester.pumpAndSettle();

    expect(find.text('Isi pengumuman uji.'), findsOneWidget);
    expect(find.textContaining('27 September 2026'), findsOneWidget);
  });
}