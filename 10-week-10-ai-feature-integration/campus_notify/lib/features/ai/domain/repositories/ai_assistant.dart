import '../../../../core/failures.dart';

/// Kontrak lapisan data. Presentation tidak pernah tahu provider AI apa yang
/// dipakai, dan domain tidak pernah mengimpor Flutter, http, atau Riverpod.
abstract class AiAssistant {
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String question,
  });
}
