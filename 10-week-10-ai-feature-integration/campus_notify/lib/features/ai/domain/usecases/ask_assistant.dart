import '../../../../core/failures.dart';
import '../repositories/ai_assistant.dart';

/// Prompt sistem dipatok di domain supaya persona dan batasnya tidak bisa
/// diubah diam-diam dari widget. Batas privasi ditulis eksplisit di sini.
const kSystemPrompt =
    'Kamu asisten kampus Politeknik Negeri Malang. Jawab dalam Bahasa Indonesia, '
    'maksimal 3 kalimat, tanpa membahas data pribadi pengguna. '
    'Bila pertanyaan di luar topik kampus, tolak dengan sopan.';

/// Aturan pemakaian sebelum memanggil API: pertanyaan kosong ditolak lokal,
/// sehingga tidak ada biaya untuk request yang tidak mungkin dijawab.
class AskAssistant {
  const AskAssistant(this._assistant);

  final AiAssistant _assistant;

  Future<({String? answer, Failure? failure})> call(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return Future.value((
        answer: null,
        failure: const LocalFailure('Tuliskan pertanyaan lebih dulu.'),
      ));
    }
    if (trimmed.length > 500) {
      return Future.value((
        answer: null,
        failure: const LocalFailure('Pertanyaan maksimal 500 karakter.'),
      ));
    }
    return _assistant.ask(systemPrompt: kSystemPrompt, question: trimmed);
  }
}
