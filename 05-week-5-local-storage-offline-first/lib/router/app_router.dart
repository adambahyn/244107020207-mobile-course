import 'package:go_router/go_router.dart';

import '../pages/note_detail_page.dart';
import '../pages/notes_page.dart';
import '../pages/posts_page.dart';
import '../pages/settings_page.dart';

/// Path/name terpusat supaya tidak ada widget yang menulis `'/note/1'` sendiri.
abstract final class AppRoutes {
  static const notes = '/';
  static const noteName = 'note';
  static const notePath = '/note/:id';
  static String note(int id) => '/note/$id';

  static const posts = '/posts';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.notes,
  routes: [
    GoRoute(
      path: AppRoutes.notes,
      builder: (context, state) => const NotesPage(),
    ),
    // Di level atas, bukan nested, supaya `/note/3` bisa dibuka langsung.
    GoRoute(
      path: AppRoutes.notePath,
      name: AppRoutes.noteName,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return NoteDetailPage(noteId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.posts,
      builder: (context, state) => const PostsPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
