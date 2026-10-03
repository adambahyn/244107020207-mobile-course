import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/sync.dart';

/// Repository palsu: tidak menyentuh SQLite sungguhan.
class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<Note?> fetchNote(int id) async {
    if (throwError) throw Exception('db locked (simulasi)');
    for (final n in items) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Future<int> countDirty() => Future.value(items.where((n) => n.dirty).length);
}

void main() {
  group('Note model', () {
    test('fromMap aman terhadap field yang hilang', () {
      final note = Note.fromMap({'title': 'Belanja'});
      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
      expect(note.id, isNull);
    });

    test('flag dirty bertahan pada serialisasi', () {
      final note = Note(
        title: 'a',
        updatedAt: DateTime(2026, 9, 18),
        dirty: true,
      );
      final restored = Note.fromMap(note.toMap());
      expect(restored.dirty, isTrue);
    });

    test('toMap menyimpan dirty sebagai 1/0', () {
      final note = Note(title: 'a', updatedAt: DateTime(2026), dirty: true);
      expect(note.toMap()['dirty'], 1);
      expect(note.copyWith(dirty: false).toMap()['dirty'], 0);
    });

    test(
      'fromMap menoleransi List pada field angka (cast biasa akan meledak)',
      () {
        expect(
          () => Note.fromMap({
            'id': [1, 2, 3],
            'dirty': {'v': 1},
            'title': 'x',
          }),
          returnsNormally,
        );
      },
    );

    test('updated_at rusak jatuh ke epoch, bukan exception', () {
      final note = Note.fromMap({'title': 'x', 'updated_at': 'bukan-tanggal'});
      expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('Provider dengan repository palsu', () {
    test('provider sukses membaca catatan', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(
              items: [Note(id: 1, title: 'Tes', updatedAt: DateTime.now())],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notes = await container.read(notesProvider.future);
      expect(notes.length, 1);
      expect(notes.first.title, 'Tes');
    });

    test('provider error bila repository melempar', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('dirtyCountProvider menghitung catatan dirty', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(
              items: [
                Note(id: 1, title: 'a', updatedAt: DateTime.now(), dirty: true),
                Note(id: 2, title: 'b', updatedAt: DateTime.now()),
                Note(id: 3, title: 'c', updatedAt: DateTime.now(), dirty: true),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(notesProvider.future);
      expect(await container.read(dirtyCountProvider.future), 2);
    });

    test('noteByIdProvider mengembalikan null untuk id hilang', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(
              items: [Note(id: 7, title: 'ada', updatedAt: DateTime.now())],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(notesProvider.future);
      expect((await container.read(noteByIdProvider(7).future))?.title, 'ada');
      expect(await container.read(noteByIdProvider(99).future), isNull);
    });
  });

  group('SyncNotes', () {
    test('nol dirty: tidak mengunggah apa pun', () async {
      final repo = FakeNoteRepository(
        items: [Note(id: 1, title: 'a', updatedAt: DateTime.now())],
      );
      expect(await syncNotesForTest(repo), 0);
    });
  });
}

/// [syncNotes] menerima [NoteRepository]; [FakeNoteRepository] adalah turunan
/// jadi signature-nya cocok tanpa cast.
Future<int> syncNotesForTest(NoteRepository repo) => syncNotes(repo);
