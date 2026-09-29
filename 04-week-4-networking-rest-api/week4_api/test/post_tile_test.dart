// Test untuk widget `PostTile`.
//
// Tujuan ekstraksi: baris post punya satu definisi dan bisa diuji tanpa
// membangun seluruh halaman. Test di bawah membuktikan variasi tampilan
// (showBody / onTap) bekerja, dan tidak ada yang crash saat field kosong.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/widgets/post_tile.dart';

const _post = Post(
  userId: 1,
  id: 7,
  title: 'judul post',
  body: 'isi badan post',
);

/// Membungkus [PostTile] dengan MaterialApp minimal.
Future<void> _pumpTile(WidgetTester tester, Widget tile) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: tile)));
}

void main() {
  testWidgets('menampilkan id, title, dan body', (tester) async {
    await _pumpTile(tester, const PostTile(post: _post));

    // id tampil di avatar kiri.
    expect(find.text('7'), findsOneWidget);
    expect(find.text('judul post'), findsOneWidget);
    expect(find.text('isi badan post'), findsOneWidget);
  });

  testWidgets('showBody: false menyembunyikan body', (tester) async {
    await _pumpTile(tester, const PostTile(post: _post, showBody: false));

    // title tetap ada, body hilang -> daftar jadi lebih padat.
    expect(find.text('judul post'), findsOneWidget);
    expect(find.text('isi badan post'), findsNothing);
  });

  testWidgets('onTap dipanggil saat baris ditekan', (tester) async {
    var tapped = 0;
    await _pumpTile(tester, PostTile(post: _post, onTap: () => tapped++));

    await tester.tap(find.byType(PostTile));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tanpa onTap: tidak ada chevron dan tidak bisa ditekan', (
    tester,
  ) async {
    await _pumpTile(tester, const PostTile(post: _post));

    // Panah penanda "bisa dibuka" tidak muncul.
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    // ListTile dengan onTap null memang tidak memicu InkWell tap.
    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(listTile.onTap, isNull);
  });

  testWidgets('dengan onTap: chevron muncul', (tester) async {
    await _pumpTile(tester, PostTile(post: _post, onTap: () {}));

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('judul panjang dielipsis, tidak melebihi 1 baris', (
    tester,
  ) async {
    final longPost = _post.copyWith(title: 'judul ' * 200);
    await _pumpTile(tester, PostTile(post: longPost));

    final title = tester.widget<Text>(find.text('judul ' * 200));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('field kosong tidak membuat crash', (tester) async {
    // Hasil `fromJson` yang aman-null bisa menghasilkan title/body kosong.
    // Widget tetap harus bisa dibangun.
    const emptyPost = Post(userId: 0, id: 0, title: '', body: '');

    await _pumpTile(tester, const PostTile(post: emptyPost));

    expect(find.byType(PostTile), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
