// Widget test: memastikan UI bereaksi terhadap perubahan state provider.
//
// Dua lapis pengujian:
//  1. widget diuji lewat `ProviderContainer` + `UncontrolledProviderScope`,
//     sehingga test bisa mengubah state langsung dari notifier (bukan hanya
//     lewat interaksi tap) dan memeriksa reaksi UI;
//  2. navigasi GoRouter `/` <-> `/stats` diuji lewat NavigationBar, plus
//     pemeriksaan bahwa TodoTile terpisah dari halaman daftar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';
import 'package:week3_todo/pages/stats_page.dart';
import 'package:week3_todo/pages/todo_page.dart';
import 'package:week3_todo/providers/todo_provider.dart';
import 'package:week3_todo/widgets/todo_tile.dart';

void main() {
  late ProviderContainer container;
  late TodoListNotifier todoNotifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    todoNotifier = container.read(todoListProvider.notifier);
  });

  /// Memasang aplikasi dengan container yang sama, jadi test bisa mengubah
  /// state provider dan melihat UI bereaksi.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('daftar kosong menampilkan placeholder', (tester) async {
    await pumpApp(tester);

    expect(find.text('Belum ada tugas'), findsOneWidget);
    expect(find.byType(TodoTile), findsNothing);
  });

  testWidgets('UI bereaksi saat todoListProvider bertambah', (tester) async {
    await pumpApp(tester);
    expect(find.text('Belum ada tugas'), findsOneWidget);

    // Ubah state LANGSUNG lewat notifier — tanpa tap, tanpa dialog.
    todoNotifier.add('Belajar Riverpod');
    await tester.pump();

    expect(find.text('Belum ada tugas'), findsNothing);
    expect(find.text('Belajar Riverpod'), findsOneWidget);
    expect(find.byType(TodoTile), findsOneWidget);
  });

  testWidgets('UI bereaksi saat tugas ditandai selesai', (tester) async {
    todoNotifier.add('Belajar Riverpod');
    await pumpApp(tester);

    // Tap Checkbox -> notifier.toggle -> provider ter-update -> UI render ulang.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final Text title = tester.widget<Text>(find.text('Belajar Riverpod'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('UI bereaksi saat tugas dihapus', (tester) async {
    todoNotifier.add('Belajar Riverpod');
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    expect(find.text('Belajar Riverpod'), findsNothing);
    expect(find.text('Belum ada tugas'), findsOneWidget);
  });

  testWidgets('filter "belum selesai" bereaksi pada perubahan state',
      (tester) async {
    todoNotifier.add('Belanja');
    todoNotifier.add('Cuci mobil');
    todoNotifier.toggle(1); // 'Cuci mobil' selesai
    await pumpApp(tester);

    expect(find.byType(TodoTile), findsNWidgets(2));

    await tester.tap(find.text('Belum selesai'));
    await tester.pumpAndSettle();

    // Hanya satu tugas tersisa, dan itu bukan yang selesai.
    expect(find.byType(TodoTile), findsOneWidget);
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Cuci mobil'), findsNothing);

    // Menyelesaikan 'Belanja' dari UI -> hilang dari daftar terfilter.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(find.byType(TodoTile), findsNothing);
    expect(find.text('Belum ada tugas'), findsOneWidget);
  });

  group('navigasi GoRouter', () {
    testWidgets("route '/' menampilkan daftar tugas", (tester) async {
      await pumpApp(tester);

      expect(find.byType(TodoPage), findsOneWidget);
      expect(find.byType(StatsPage), findsNothing);
    });

    testWidgets('NavigationBar berpindah dari / ke /stats dan sebaliknya',
        (tester) async {
      todoNotifier.add('Belanja');
      await pumpApp(tester);

      // Tab "Statistik" -> halaman statistik menampilkan angka dari provider.
      await tester.tap(find.text('Statistik'));
      await tester.pumpAndSettle();

      expect(find.byType(StatsPage), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('0% tugas selesai'), findsOneWidget);

      // Tab "Daftar" -> kembali ke daftar.
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.byType(TodoPage), findsOneWidget);
      expect(find.text('Belanja'), findsOneWidget);
    });

    testWidgets('statistik bereaksi saat tugas diselesaikan di tab lain',
        (tester) async {
      todoNotifier.add('Belanja');
      todoNotifier.add('Cuci mobil');
      await pumpApp(tester);

      // Selesaikan satu tugas dari halaman daftar.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      await tester.tap(find.text('Statistik'));
      await tester.pumpAndSettle();

      // total 2, selesai 1 -> 50%.
      expect(find.text('50% tugas selesai'), findsOneWidget);
    });
  });
}
