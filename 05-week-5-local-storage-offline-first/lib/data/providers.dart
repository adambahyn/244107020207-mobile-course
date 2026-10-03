import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/local/post.dart';
import '../data/prefs.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';

/// Format waktu lokal `YYYY-MM-DD HH:MM` tanpa dependensi `intl`.
/// ponytail: tidak ada locale-aware formatting; ganti ke `intl` kalau perlu.
String formatTimestamp(DateTime dt) {
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} '
      '${two(l.hour)}:${two(l.minute)}';
}

/// Format string ISO-8601 dari SharedPreferences menjadi `YYYY-MM-DD HH:MM`.
/// Nilai null atau tidak bisa di-parse tampil sebagai 'belum tercatat'.
String formatLastOpened(String? iso) {
  if (iso == null) return 'belum tercatat';
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? 'belum tercatat' : formatTimestamp(parsed);
}

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final postCacheRepositoryProvider = Provider<PostCacheRepository>(
  (ref) => PostCacheRepository(),
);

/// Simulasi jaringan. Diuji tanpa internet: ganti dengan Dio Minggu 4.
final remotePostsProvider = Provider<Future<List<Post>> Function()>((ref) {
  return () async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      Post(id: 1, userId: 1, title: 'Post 1 dari server', body: 'Isi post 1'),
      Post(id: 2, userId: 1, title: 'Post 2 dari server', body: 'Isi post 2'),
      Post(id: 3, userId: 2, title: 'Post 3 dari server', body: 'Isi post 3'),
    ];
  };
});

// --- Preferensi ---------------------------------------------------------

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

/// autoDispose: nilai dibaca ulang tiap kali halaman Pengaturan dibuka,
/// supaya "Terakhir dibuka" tidak menampilkan snapshot lama.
final lastOpenedProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(prefsRepositoryProvider).getLastOpened(),
  retry: (_, _) => null,
);

// --- Catatan ------------------------------------------------------------

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
  retry: (_, _) => null,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() => ref.watch(noteRepositoryProvider).fetchNotes();

  Future<void> add(String title, [String body = '']) async {
    await ref.read(noteRepositoryProvider).addNote(title: title, body: body);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    ref.invalidateSelf();
    await future;
  }

  Future<int> sync() async {
    final uploaded = await syncNotes(ref.read(noteRepositoryProvider));
    ref.invalidateSelf();
    await future;
    return uploaded;
  }
}

/// Jumlah catatan belum tersinkron — badge "antrean sync".
final dirtyCountProvider = FutureProvider<int>((ref) {
  // Ikut refresh setiap kali daftar catatan berubah.
  ref.watch(notesProvider);
  return ref.watch(noteRepositoryProvider).countDirty();
}, retry: (_, _) => null);

/// Detail catatan dibaca langsung dari repository lokal, bukan dari state
/// halaman list — jadi `/note/:id` tetap benar setelah ditautkan langsung.
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  ref.watch(notesProvider);
  return ref.watch(noteRepositoryProvider).fetchNote(id);
}, retry: (_, _) => null);

// --- Cache-first posts --------------------------------------------------

/// Toggle simulasi offline agar demo dan test tidak bergantung Wi-Fi.
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    // Cache-first berubah arti saat offline dimatikan: paksa halaman post
    // membaca ulang cache & mencoba refresh jaringan.
    ref.invalidate(postsProvider);
  }
}

class PostsState {
  const PostsState({required this.posts, required this.fromCache, this.error});

  final List<Post> posts;
  final bool fromCache;
  final Object? error;
}

final postsProvider = AsyncNotifierProvider<PostsNotifier, PostsState>(
  PostsNotifier.new,
  retry: (_, _) => null,
);

class PostsNotifier extends AsyncNotifier<PostsState> {
  @override
  Future<PostsState> build() async {
    final cache = await ref
        .watch(postCacheRepositoryProvider)
        .readCachedPosts();
    // Cache-first: kembalikan cache seketika supaya UI tidak blank saat offline.
    // Refresh jaringan dijadwalkan SETELAH build() selesai, supaya penulisan
    // `state` di _refreshInBackground tidak balapan dengan nilai return build()
    // (dulu `unawaited` di sini, hasil refresh bisa tertimpa cache kosong).
    Future.microtask(_refreshInBackground);
    return PostsState(posts: cache, fromCache: cache.isNotEmpty);
  }

  /// Refresh dari jaringan lalu simpan ke cache. Kegagalan tidak membuang
  /// data cache yang sudah tampil.
  Future<void> _refreshInBackground() async {
    if (ref.read(forceOfflineProvider)) return;
    try {
      final fresh = await ref.read(remotePostsProvider)();
      await ref.read(postCacheRepositoryProvider).savePosts(fresh);
      if (ref.mounted) {
        state = AsyncData(PostsState(posts: fresh, fromCache: false));
      }
    } catch (err) {
      if (ref.mounted) {
        final current = state.value;
        state = AsyncData(
          PostsState(
            posts: current?.posts ?? const [],
            fromCache: current?.fromCache ?? true,
            error: err,
          ),
        );
      }
    }
  }

  Future<void> refreshNow() => _refreshInBackground();
}

final lastCachedAtProvider = FutureProvider<DateTime?>((ref) {
  ref.watch(postsProvider);
  return ref.watch(postCacheRepositoryProvider).lastCachedAt();
}, retry: (_, _) => null);
