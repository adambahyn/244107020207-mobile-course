import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';

/// Repositori cache untuk data API Minggu 4. Terpisah dari
/// [NoteRepository] karena cache posts selalu ditimpa penuh dari jaringan,
/// sementara catatan punya antrean sync sendiri.
class PostCacheRepository {
  PostCacheRepository({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows
        .map((row) => CachedPost.fromRow(row).toPost())
        .whereType<Post>()
        .toList();
  }

  Future<DateTime?> lastCachedAt() async {
    final db = await _openDb();
    final rows = await db.query(
      'cached_posts',
      columns: ['cached_at'],
      orderBy: 'cached_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['cached_at'] as String? ?? '');
  }

  Future<void> savePosts(List<Post> posts) async {
    final db = await _openDb();
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    // Cache adalah snapshot jaringan terakhir: bersihkan dulu supaya post yang
    // sudah dihapus di server tidak tertinggal selamanya.
    batch.delete('cached_posts');
    for (final post in posts) {
      batch.insert('cached_posts', {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}

/// Simulasi upload catatan dirty. Pada project nyata, tiap catatan di sini
/// dikirim ke REST API lalu ditandai bersih hanya bila server menjawab 2xx.
/// Yang dinilai codelab Minggu 5 adalah mekanismenya, bukan servernya.
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
