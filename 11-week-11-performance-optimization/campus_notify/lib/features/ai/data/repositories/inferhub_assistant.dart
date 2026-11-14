import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/failures.dart';
import '../../domain/repositories/ai_assistant.dart';
import '../datasources/ai_key_store.dart';

/// Implementasi [AiAssistant] di atas API Inferhub (OpenAI compatible).
/// Key dibaca dari secure storage tiap panggilan, tidak disimpan di memori
/// jangka panjang dan tidak pernah ikut ke dalam pesan log.
class InferhubAssistant implements AiAssistant {
  InferhubAssistant({
    required this.keyStore,
    http.Client? client,
    this.endpoint = 'https://api.inferhub.dev/v1/chat/completions',
    this.model = 'combo/uu',
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final AiKeyStore keyStore;
  final http.Client _client;
  final String endpoint;
  final String model;
  final Duration timeout;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String question,
  }) async {
    final key = await keyStore.read();
    if (key == null || key.isEmpty) {
      return (
        answer: null,
        failure: const AuthFailure('API key AI belum diatur. Buka menu kunci.'),
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': question},
              ],
              'max_tokens': 400,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return (
          answer: null,
          failure: const AuthFailure('API key ditolak penyedia layanan AI.'),
        );
      }
      if (response.statusCode != 200) {
        return (
          answer: null,
          failure: NetworkFailure(
            'Layanan AI membalas ${response.statusCode}. Coba lagi nanti.',
          ),
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = body['choices'] as List<dynamic>?;
      final message = choices?.isEmpty ?? true
          ? null
          : (choices!.first as Map<String, dynamic>)['message']
                as Map<String, dynamic>?;
      final text = (message?['content'] as String?)?.trim() ?? '';

      if (text.isEmpty) {
        return (
          answer: null,
          failure: const LocalFailure(
            'Model tidak mengembalikan teks. Coba pertanyaan lain.',
          ),
        );
      }
      return (answer: text, failure: null);
    } on TimeoutException {
      return (
        answer: null,
        failure: const NetworkFailure('Layanan AI terlalu lama menjawab.'),
      );
    } on SocketException {
      return (
        answer: null,
        failure: const NetworkFailure('Tidak ada koneksi internet.'),
      );
    } on http.ClientException {
      return (
        answer: null,
        failure: const NetworkFailure('Koneksi ke layanan AI gagal.'),
      );
    } on FormatException {
      return (
        answer: null,
        failure: const LocalFailure('Balasan layanan AI tidak dapat dibaca.'),
      );
    }
  }
}
