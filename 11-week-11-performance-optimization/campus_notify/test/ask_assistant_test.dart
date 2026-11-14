import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai/domain/repositories/ai_assistant.dart';
import 'package:campus_notify/features/ai/domain/usecases/ask_assistant.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpyAssistant implements AiAssistant {
  int calls = 0;
  String? lastQuestion;
  String? lastSystem;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String question,
  }) async {
    calls++;
    lastQuestion = question;
    lastSystem = systemPrompt;
    return (answer: 'jawaban', failure: null);
  }
}

void main() {
  test('pertanyaan kosong ditolak tanpa memanggil API', () async {
    final spy = _SpyAssistant();
    final result = await AskAssistant(spy)('   ');
    expect(result.answer, isNull);
    expect(result.failure, isA<LocalFailure>());
    expect(spy.calls, 0);
  });

  test('pertanyaan lebih dari 500 karakter ditolak lokal', () async {
    final spy = _SpyAssistant();
    final result = await AskAssistant(spy)('a' * 501);
    expect(result.failure, isA<LocalFailure>());
    expect(spy.calls, 0);
  });

  test('pertanyaan wajar diteruskan dalam bentuk terpangkas', () async {
    final spy = _SpyAssistant();
    final result = await AskAssistant(spy)('  jam layanan akademik?  ');
    expect(result.answer, 'jawaban');
    expect(spy.calls, 1);
    expect(spy.lastQuestion, 'jam layanan akademik?');
    expect(spy.lastSystem, contains('Bahasa Indonesia'));
    expect(spy.lastSystem, contains('data pribadi'));
  });
}
