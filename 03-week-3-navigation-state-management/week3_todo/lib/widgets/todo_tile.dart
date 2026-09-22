import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

/// Satu baris tugas.
///
/// Dipisahkan dari [TodoPage] supaya `build()` halaman tetap pendek dan baris
/// ini bisa diuji/di-preview sendiri. Widget ini TIDAK menyimpan state: semua
/// aksi diteruskan ke provider lewat [WidgetRef] yang di-`watch` langsung di
/// dalam build, sehingga perubahan state apa pun otomatis me-render ulang baris.
class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.todo, required this.index});

  final Todo todo;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(todoListProvider.notifier);

    return ListTile(
      leading: Checkbox(
        value: todo.done,
        onChanged: (_) => notifier.toggle(index),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => notifier.remove(index),
      ),
    );
  }
}
