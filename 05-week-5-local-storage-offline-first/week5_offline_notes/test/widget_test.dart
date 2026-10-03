import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/local/post.dart';
import 'package:week5_offline_notes/data/prefs.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/sync.dart';
import 'package:week5_offline_notes/pages/posts_page.dart';
import 'package:week5_offline_notes/pages/settings_page.dart';
import 'package:week5_offline_notes/widgets/note_tile.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('NoteTile', () {
    testWidgets('menampilkan badge belum tersinkron', (tester) async {
      await tester.pumpWidget(
        wrap(
          NoteTile(
            note: Note(title: 'Judul', updatedAt: DateTime(2026), dirty: true),
          ),
        ),
      );
      expect(find.text('Judul'), findsOneWidget);
      expect(find.byKey(const Key('dirty-badge')), findsOneWidget);
    });

    testWidgets('menyembunyikan badge saat catatan bersih', (tester) async {
      await tester.pumpWidget(
        wrap(
          NoteTile(
            note: Note(title: 'Bersih', updatedAt: DateTime(2026)),
          ),
        ),
      );
      expect(find.byKey(const Key('dirty-badge')), findsNothing);
    });

    testWidgets('memanggil onTap dan onDelete', (tester) async {
      var tapped = false;
      var deleted = false;
      await tester.pumpWidget(
        wrap(
          NoteTile(
            note: Note(title: 'Judul', updatedAt: DateTime(2026)),
            onTap: () => tapped = true,
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.tap(find.text('Judul'));
      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(tapped, isTrue);
      expect(deleted, isTrue);
    });
  });

  group('SettingsPage', () {
    testWidgets('tap baris Simulasi offline menyalakan toggle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // SharedPreferences tidak tersedia di test VM.
          overrides: [
            prefsRepositoryProvider.overrideWithValue(FakePrefsRepository()),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      SwitchListTile toggle() => tester.widget<SwitchListTile>(
        find.byKey(const Key('force-offline-switch')),
      );
      expect(toggle().value, isFalse);

      // Tap judul, bukan switch: seluruh baris harus responsif.
      await tester.tap(find.text('Simulasi offline'));
      await tester.pumpAndSettle();

      expect(toggle().value, isTrue);
    });
  });

  group('Cache-first posts', () {
    testWidgets(
      'menampilkan pesan cache kosong saat offline & belum ada cache',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              forceOfflineProvider.overrideWith(_ForceOffline.new),
              postCacheRepositoryProvider.overrideWithValue(
                FakePostCacheRepository(),
              ),
              remotePostsProvider.overrideWithValue(
                () => Future.value(const <Post>[]),
              ),
            ],
            child: const MaterialApp(home: PostsPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('empty-posts')), findsOneWidget);
      },
    );

    testWidgets('menampilkan post dari cache tanpa jaringan', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            forceOfflineProvider.overrideWith(_ForceOffline.new),
            postCacheRepositoryProvider.overrideWithValue(
              FakePostCacheRepository(
                posts: const [Post(id: 9, userId: 1, title: 'Dari cache')],
              ),
            ),
            remotePostsProvider.overrideWithValue(
              () => Future.value(const <Post>[]),
            ),
          ],
          child: const MaterialApp(home: PostsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dari cache'), findsOneWidget);
      expect(find.byKey(const Key('empty-posts')), findsNothing);
    });

    test('online mengisi cache, lalu offline membacanya kembali', () async {
      final cache = FakePostCacheRepository();
      final container = ProviderContainer(
        overrides: [
          postCacheRepositoryProvider.overrideWithValue(cache),
          remotePostsProvider.overrideWithValue(
            () => Future.value(const [
              Post(id: 1, userId: 1, title: 'Dari server'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Online: refresh background menyimpan hasil jaringan ke cache.
      await container.read(postsProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(cache.saved.single.title, 'Dari server');

      // Offline: build() membaca cache, tidak menulis ulang.
      container.read(forceOfflineProvider.notifier).toggle();
      final offline = await container.read(postsProvider.future);
      expect(offline.fromCache, isTrue);
      expect(offline.posts.single.title, 'Dari server');
    });
  });
}

class _ForceOffline extends ForceOfflineNotifier {
  @override
  bool build() => true;
}

/// Preferensi palsu: tidak menyentuh SharedPreferences (plugin absen di test).
class FakePrefsRepository extends PrefsRepository {
  bool darkMode = false;
  String? lastOpened;

  @override
  Future<bool> getDarkMode() async => darkMode;

  @override
  Future<void> setDarkMode(bool value) async => darkMode = value;

  @override
  Future<String?> getLastOpened() async => lastOpened;

  @override
  Future<void> markOpenedNow() async =>
      lastOpened = DateTime.now().toIso8601String();
}

/// Cache palsu: tidak menyentuh SQLite sungguhan (plugin tidak tersedia di test).
class FakePostCacheRepository extends PostCacheRepository {
  FakePostCacheRepository({this.posts = const []})
    : super(openDb: () => throw UnimplementedError());

  final List<Post> posts;
  List<Post> saved = const [];

  @override
  Future<List<Post>> readCachedPosts() async => saved.isEmpty ? posts : saved;

  @override
  Future<DateTime?> lastCachedAt() async => null;

  @override
  Future<void> savePosts(List<Post> posts) async => saved = posts;
}
