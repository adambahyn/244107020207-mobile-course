import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/ai_key_store.dart';
import '../../data/repositories/inferhub_assistant.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_assistant.dart';
import '../../domain/usecases/ask_assistant.dart';

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

final aiAssistantProvider = Provider<AiAssistant>(
  (ref) => InferhubAssistant(keyStore: ref.watch(aiKeyStoreProvider)),
);

final askAssistantProvider = Provider<AskAssistant>(
  (ref) => AskAssistant(ref.watch(aiAssistantProvider)),
);

/// Status kunci untuk ditampilkan dalam bentuk tersamar saja.
final aiKeyStatusProvider = FutureProvider<String?>((ref) async {
  final key = await ref.watch(aiKeyStoreProvider).read();
  return key == null || key.isEmpty ? null : AiKeyStore.mask(key);
});

class ChatState {
  const ChatState({
    this.messages = const [],
    this.sending = false,
    this.failure,
    this.requests = 0,
  });

  final List<ChatMessage> messages;
  final bool sending;
  final Failure? failure;

  /// Penghitung permintaan pada sesi berjalan, dipakai sebagai pagar biaya.
  final int requests;

  bool get exhausted => requests >= maxRequestsPerSession;
  static const maxRequestsPerSession = 20;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    Failure? failure,
    bool clearFailure = false,
    int? requests,
  }) => ChatState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    failure: clearFailure ? null : (failure ?? this.failure),
    requests: requests ?? this.requests,
  );
}

/// Satu notifier memegang percakapan. autoDispose supaya riwayat tidak
/// menumpuk di memori dan pagar biaya kembali nol saat halaman ditutup.
class ChatNotifier extends Notifier<ChatState> {
  String _lastQuestion = '';

  @override
  ChatState build() => const ChatState();

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.sending) return;
    if (state.exhausted) {
      state = state.copyWith(
        failure: const LocalFailure(
          'Batas 20 permintaan per sesi tercapai. Tutup halaman untuk mengulang.',
        ),
      );
      return;
    }

    _lastQuestion = text;
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: text),
      ],
      sending: true,
      clearFailure: true,
      requests: state.requests + 1,
    );

    final result = await ref.read(askAssistantProvider).call(text);
    final answer = result.answer;
    final failure = result.failure;

    if (failure != null) {
      state = state.copyWith(sending: false, failure: failure);
      return;
    }
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.assistant, text: answer!),
      ],
      sending: false,
      clearFailure: true,
    );
  }

  Future<void> retry() => send(_lastQuestion);
}

final chatProvider = NotifierProvider.autoDispose<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
