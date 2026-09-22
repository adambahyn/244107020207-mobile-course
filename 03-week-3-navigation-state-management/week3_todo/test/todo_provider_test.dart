// Unit test untuk provider turunan (derived provider) pada aplikasi ToDo.
//
// Yang diuji: filteredTodoListProvider (logika filter) dan todoStatsProvider
// (agregat untuk halaman /stats). Keduanya TIDAK menyimpan state sendiri —
// nilainya dihitung ulang dari todoListProvider, dan itu yang diperiksa di sini
// dengan cara membandingkan isi container sebelum & sesudah aksi.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/todo_provider.dart';

void main() {
  late ProviderContainer container;
  late TodoListNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(todoListProvider.notifier);
  });

  void addTodos() {
    notifier.add('Belanja');
    notifier.add('Cuci mobil');
    notifier.add('Kerjakan PR');
    notifier.toggle(1); // 'Cuci mobil' -> selesai
  }

  group('filteredTodoListProvider', () {
    test('filter "semua" mengembalikan seluruh tugas', () {
      addTodos();

      expect(container.read(filteredTodoListProvider).length, 3);
    });

    test('filter "belum selesai" hanya mengembalikan todo.done == false', () {
      addTodos();
      container
          .read(todoFilterProvider.notifier)
          .set(TodoFilter.active);

      final titles =
          container.read(filteredTodoListProvider).map((t) => t.title).toList();

      expect(titles, <String>['Belanja', 'Kerjakan PR']);
      expect(titles, isNot(contains('Cuci mobil')));
    });

    test('filter "selesai" hanya mengembalikan todo.done == true', () {
      addTodos();
      container
          .read(todoFilterProvider.notifier)
          .set(TodoFilter.completed);

      expect(
        container.read(filteredTodoListProvider).map((t) => t.title).toList(),
        <String>['Cuci mobil'],
      );
    });

    test('provider turunan ikut berubah saat state sumber berubah', () {
      addTodos();
      container
          .read(todoFilterProvider.notifier)
          .set(TodoFilter.active);
      expect(container.read(filteredTodoListProvider).length, 2);

      // Menambah tugas baru -> hasil filter bertambah tanpa perlu invalidate.
      notifier.add('Olahraga');
      expect(container.read(filteredTodoListProvider).length, 3);

      // Menyelesaikan tugas -> hilang dari daftar "belum selesai".
      notifier.toggle(0); // 'Belanja' -> selesai
      expect(
        container.read(filteredTodoListProvider).map((t) => t.title).toList(),
        <String>['Kerjakan PR', 'Olahraga'],
      );
    });

    test('mengubah filter tidak mengubah data tugas asli', () {
      addTodos();

      container
          .read(todoFilterProvider.notifier)
          .set(TodoFilter.active);

      expect(container.read(todoListProvider).length, 3);
    });
  });

  group('todoStatsProvider', () {
    test('awalnya nol', () {
      final stats = container.read(todoStatsProvider);

      expect(stats.total, 0);
      expect(stats.done, 0);
      expect(stats.active, 0);
      expect(stats.completionRate, 0);
    });

    test('menghitung total / selesai / belum dan rasio penyelesaian', () {
      addTodos();

      final stats = container.read(todoStatsProvider);

      expect(stats.total, 3);
      expect(stats.done, 1);
      expect(stats.active, 2);
      expect(stats.completionRate, closeTo(1 / 3, 1e-9));
    });

    test('tidak terpengaruh filter yang sedang aktif', () {
      addTodos();
      container
          .read(todoFilterProvider.notifier)
          .set(TodoFilter.active);

      // Statistik selalu atas SELURUH tugas, bukan hasil filter.
      expect(container.read(todoStatsProvider).total, 3);
      expect(container.read(todoStatsProvider).done, 1);
    });
  });

  group('TodoListNotifier', () {
    test('toggle dan remove tidak memutasi list lama (immutable)', () {
      notifier.add('A');
      final List<Todo> before = container.read(todoListProvider);

      notifier.toggle(0);
      final List<Todo> afterToggle = container.read(todoListProvider);

      expect(identical(before, afterToggle), isFalse);
      expect(before.single.done, isFalse); // list lama tidak berubah

      notifier.remove(0);
      expect(container.read(todoListProvider), isEmpty);
      expect(afterToggle.length, 1); // list lama tetap utuh
    });
  });
}
