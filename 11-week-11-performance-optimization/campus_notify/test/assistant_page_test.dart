import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai/domain/repositories/ai_assistant.dart';
import 'package:campus_notify/features/ai/presentation/pages/assistant_page.dart';
import 'package:campus_notify/features/ai/presentation/providers/ai_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OkAssistant implements AiAssistant {
  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String question,
  }) async =>
      (answer: 'Layanan akademik buka 08.00 sampai 16.00.', failure: null);
}

class _BusyAssistant implements AiAssistant {
  int calls = 0;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String question,
  }) async {
    calls++;
    return (
      answer: null,
      failure: const NetworkFailure('Layanan AI terlalu lama menjawab.'),
    );
  }
}

Widget _app(AiAssistant assistant) => ProviderScope(
  overrides: [
    aiAssistantProvider.overrideWithValue(assistant),
    aiKeyStatusProvider.overrideWith((ref) async => 'sk-airo-bR********'),
  ],
  child: const MaterialApp(home: AssistantPage()),
);

void main() {
  testWidgets('tanpa key status kunci tampil tersamar', (tester) async {
    await tester.pumpWidget(_app(_OkAssistant()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-empty')), findsOneWidget);
    expect(
      find.textContaining('sk-airo-bR'),
      findsOneWidget,
      reason: 'status kunci hanya boleh tampil dalam bentuk tersamar',
    );
  });

  testWidgets('kirim pertanyaan menampilkan jawaban asisten', (tester) async {
    await tester.pumpWidget(_app(_OkAssistant()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('chat-input')), 'jam layanan?');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-message-0')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-1')), findsOneWidget);
    expect(find.textContaining('08.00'), findsOneWidget);
    expect(find.text('1/20'), findsOneWidget);
  });

  testWidgets('kegagalan API menampilkan mode offline dan tombol coba lagi', (
    tester,
  ) async {
    final busy = _BusyAssistant();
    await tester.pumpWidget(_app(busy));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('chat-input')), 'jadwal?');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-failure')), findsOneWidget);
    expect(find.textContaining('Mode offline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-retry')));
    await tester.pumpAndSettle();
    expect(busy.calls, 2);
  });

  testWidgets('pertanyaan kosong ditolak tanpa memanggil API', (tester) async {
    final busy = _BusyAssistant();
    await tester.pumpWidget(_app(busy));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();

    expect(busy.calls, 0);
    expect(find.byKey(const Key('chat-failure')), findsNothing);
  });
}
