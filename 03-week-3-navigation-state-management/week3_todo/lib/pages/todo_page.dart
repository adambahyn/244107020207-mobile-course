import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

/// Halaman daftar tugas (route `/`).
///
/// Tipis saja: membaca daftar yang sudah tersaring dari
/// [filteredTodoListProvider] dan menyerahkan tiap baris ke [TodoTile].
class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodoListProvider);
    final filter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo Riverpod')),
      body: Column(
        children: <Widget>[
          _FilterBar(selected: filter),
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('Belum ada tugas'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) =>
                        TodoTile(todo: todos[index], index: index),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => const _AddTodoDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Dialog "Tugas baru".
///
/// Dibuat sebagai [StatefulWidget] supaya [TextEditingController]-nya punya
/// pemilik yang jelas: dibuat di `initState` dan dibuang di `dispose` sesuai
/// siklus hidup dialog, bukan setelah `showDialog` selesai (route yang sudah
/// di-pop masih dianimasikan keluar, jadi controller belum boleh dibuang).
class _AddTodoDialog extends ConsumerStatefulWidget {
  const _AddTodoDialog();

  @override
  ConsumerState<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends ConsumerState<_AddTodoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      ref.read(todoListProvider.notifier).add(title);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Tambah'),
          ),
        ],
      );
}

/// Pemilih filter. Hanya menulis ke [todoFilterProvider]; penyaringan sendiri
/// dikerjakan [filteredTodoListProvider].
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.selected});

  final TodoFilter selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SegmentedButton<TodoFilter>(
        segments: TodoFilter.values
            .map(
              (filter) => ButtonSegment<TodoFilter>(
                value: filter,
                label: Text(filter.label),
              ),
            )
            .toList(growable: false),
        selected: <TodoFilter>{selected},
        onSelectionChanged: (selection) =>
            ref.read(todoFilterProvider.notifier).set(selection.first),
      ),
    );
  }
}

/// Tombol menuju halaman statistik (`/stats`) lewat GoRouter.
class StatsButton extends StatelessWidget {
  const StatsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.bar_chart),
        tooltip: 'Statistik',
        onPressed: () => context.go('/stats'),
      );
}
