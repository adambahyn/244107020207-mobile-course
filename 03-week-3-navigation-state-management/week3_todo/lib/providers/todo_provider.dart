import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model data tugas.
///
/// Immutable: setiap perubahan menghasilkan `Todo` baru lewat [copyWith],
/// tidak ada field yang dimutasi langsung.
class Todo {
  const Todo(this.title, {this.done = false});

  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

/// State utama daftar tugas.
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const <Todo>[];

  void add(String title) => state = <Todo>[...state, Todo(title)];

  void toggle(int index) {
    final todos = <Todo>[...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void remove(int index) => state = <Todo>[...state]..removeAt(index);
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

/// Filter yang sedang aktif pada halaman daftar.
enum TodoFilter {
  all('Semua'),
  active('Belum selesai'),
  completed('Selesai');

  const TodoFilter(this.label);

  final String label;
}

/// State filter aktif. Dipisah dari [todoListProvider] supaya mengubah filter
/// tidak menyentuh data tugas sama sekali.
class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void set(TodoFilter filter) => state = filter;
}

final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

/// Provider turunan (derived provider) — TIDAK menyimpan state sendiri.
///
/// Membaca [todoListProvider] dan [todoFilterProvider] dengan `ref.watch`,
/// lalu mengembalikan daftar yang sudah tersaring. Karena hasilnya dihitung
/// ulang setiap kali salah satu provider sumbernya berubah, widget yang
/// meng-`watch` provider ini otomatis ikut rebuild — inilah yang membuat
/// daftar cukup menampilkan "yang belum selesai" tanpa logika filter di UI.
final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  switch (filter) {
    case TodoFilter.all:
      return todos;
    case TodoFilter.active:
      return todos.where((todo) => !todo.done).toList(growable: false);
    case TodoFilter.completed:
      return todos.where((todo) => todo.done).toList(growable: false);
  }
});

/// Statistik ringkas untuk halaman /stats.
class TodoStats {
  const TodoStats({
    required this.total,
    required this.done,
    required this.active,
  });

  final int total;
  final int done;
  final int active;

  /// Persentase tugas selesai (0.0 - 1.0), 0 bila belum ada tugas.
  double get completionRate => total == 0 ? 0 : done / total;
}

/// Provider turunan kedua yang membaca [todoListProvider].
///
/// Halaman statistik tidak perlu tahu bentuk `List<Todo>`, cukup angka
/// agregatnya. Karena ikut bergantung pada provider sumber, nilainya selalu
/// sinkron tanpa perlu di-refresh manual.
final todoStatsProvider = Provider<TodoStats>((ref) {
  final todos = ref.watch(todoListProvider);
  final done = todos.where((todo) => todo.done).length;

  return TodoStats(
    total: todos.length,
    done: done,
    active: todos.length - done,
  );
});
