import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/ai_providers.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    _controller.clear();
    await ref.read(chatProvider.notifier).send(text);
  }

  Future<void> _editKey() async {
    final store = ref.read(aiKeyStoreProvider);
    final field = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API key AI'),
        content: TextField(
          key: const Key('ai-key-field'),
          controller: field,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Kunci Inferhub',
            helperText: 'Disimpan di penyimpanan aman perangkat',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('ai-key-save'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved ?? false) {
      await store.save(field.text);
      ref.invalidate(aiKeyStatusProvider);
    }
    field.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final keyStatus = ref.watch(aiKeyStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI'),
        actions: [
          IconButton(
            key: const Key('ai-key-button'),
            tooltip: 'Atur API key',
            icon: const Icon(Icons.key),
            onPressed: _editKey,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    keyStatus.when(
                      data: (mask) => 'Kunci: ${mask ?? '(belum diatur)'}',
                      loading: () => 'Kunci: memeriksa...',
                      error: (_, _) => 'Kunci: gagal dibaca',
                    ),
                    key: const Key('ai-key-status'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${state.requests}/${ChatState.maxRequestsPerSession}',
                  key: const Key('ai-usage'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) =>
                        _Bubble(message: state.messages[i], index: i),
                  ),
          ),
          if (state.failure != null)
            _FailureBar(
              failure: state.failure!,
              onRetry: state.sending
                  ? null
                  : () => ref.read(chatProvider.notifier).retry(),
            ),
          if (state.sending)
            const LinearProgressIndicator(key: Key('chat-loading')),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat-input'),
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Tanya seputar kampus',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('chat-send'),
                    onPressed: state.sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Tanyakan jadwal, layanan, atau pengumuman kampus. '
        'Jangan kirim data pribadi seperti NIK atau nomor telepon.',
        key: const Key('chat-empty'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.index});

  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: message.isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          key: Key('chat-message-$index'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _FailureBar extends StatelessWidget {
  const _FailureBar({required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('chat-failure'),
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${failure.message} Mode offline: pengumuman tetap dapat dibuka.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(
            key: const Key('chat-retry'),
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
