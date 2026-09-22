import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_provider.dart';

/// Halaman statistik (route `/stats`).
///
/// Tidak menghitung apa pun sendiri — semua angka berasal dari provider
/// turunan [todoStatsProvider], jadi halaman ini ikut berubah begitu daftar
/// tugas berubah.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todoStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'Total',
                    value: '${stats.total}',
                    icon: Icons.list_alt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Selesai',
                    value: '${stats.done}',
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Belum',
                    value: '${stats.active}',
                    icon: Icons.pending_actions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: stats.completionRate),
            const SizedBox(height: 8),
            Text(
              '${(stats.completionRate * 100).toStringAsFixed(0)}% tugas selesai',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.list),
              label: const Text('Kembali ke daftar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
