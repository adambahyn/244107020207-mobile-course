// Widget test untuk halaman komentar.
//
// Repositori jaringan di-override dengan data palsu supaya test tidak
// menyentuh internet dan hasilnya deterministik.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/comment_provider.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/repositories/comment_repository.dart';
import 'package:week4_api/pages/comment_list_page.dart';

/// Repository palsu yang mengembalikan daftar komentar buatan.
class _FakeRepository implements CommentRepository {
  _FakeRepository(this.comments);

  final List<Comment> comments;

  @override
  Future<List<Comment>> fetchComments(int postId) async => comments;
}

void main() {
  testWidgets('menampilkan daftar komentar dari provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(const [
              Comment(
                postId: 1,
                id: 1,
                name: 'Nama Pertama',
                email: 'satu@example.com',
                body: 'isi komentar pertama',
              ),
              Comment(
                postId: 1,
                id: 2,
                name: 'Nama Kedua',
                email: 'dua@example.com',
                body: 'isi komentar kedua',
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: CommentListPage(postId: 1)),
      ),
    );

    // State awal: masih memuat.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Data muncul di layar.
    expect(find.text('Nama Pertama'), findsOneWidget);
    expect(find.text('Nama Kedua'), findsOneWidget);
    expect(find.text('satu@example.com'), findsOneWidget);
  });

  testWidgets('menampilkan pesan kosong bila tidak ada komentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(const []),
          ),
        ],
        child: const MaterialApp(home: CommentListPage(postId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Belum ada komentar untuk post ini.'), findsOneWidget);
  });
}
