import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkAsync = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('dark-mode-switch'),
            title: const Text('Tema gelap'),
            subtitle: const Text('Disimpan di SharedPreferences'),
            value: darkAsync.value ?? false,
            onChanged: darkAsync.isLoading
                ? null
                : (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Terakhir dibuka'),
            subtitle: Text(formatLastOpened(lastOpened.value)),
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('force-offline-switch'),
            secondary: const Icon(Icons.wifi_off),
            title: const Text('Simulasi offline'),
            subtitle: const Text(
              'Paksa cache-first tanpa memanggil jaringan (untuk demo/test)',
            ),
            value: ref.watch(forceOfflineProvider),
            onChanged: (_) => ref.read(forceOfflineProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}
