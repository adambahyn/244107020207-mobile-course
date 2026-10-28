import 'dart:convert';
import 'dart:io';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai/data/datasources/ai_key_store.dart';
import 'package:campus_notify/features/ai/data/repositories/inferhub_assistant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _KeyStore extends AiKeyStore {
  _KeyStore(this.value);

  final String? value;

  @override
  Future<String?> read() async => value;
}

Map<String, dynamic> _body(String content) => {
  'choices': [
    {
      'message': {'role': 'assistant', 'content': content},
    },
  ],
};

void main() {
  test('balasan 200 dikembalikan sebagai teks', () async {
    late http.Request seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response(jsonEncode(_body('Kampus buka 08.00.')), 200);
    });

    final repo = InferhubAssistant(
      keyStore: _KeyStore('sk-uji'),
      client: client,
    );
    final result = await repo.ask(
      systemPrompt: 'sistem',
      question: 'jam buka?',
    );

    expect(result.failure, isNull);
    expect(result.answer, 'Kampus buka 08.00.');
    expect(seen.url.toString(), 'https://api.inferhub.dev/v1/chat/completions');
    expect(seen.headers['Authorization'], 'Bearer sk-uji');
    final sent = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(sent['model'], 'combo/uu');
    expect((sent['messages'] as List).first['role'], 'system');
    expect((sent['messages'] as List).last['content'], 'jam buka?');
  });

  test('tanpa key tidak ada request keluar', () async {
    var called = 0;
    final client = MockClient((_) async {
      called++;
      return http.Response('{}', 200);
    });

    final repo = InferhubAssistant(keyStore: _KeyStore(null), client: client);
    final result = await repo.ask(systemPrompt: 's', question: 'q');

    expect(result.failure, isA<AuthFailure>());
    expect(called, 0);
  });

  test('401 menjadi AuthFailure', () async {
    final client = MockClient((_) async => http.Response('{"error":1}', 401));
    final repo = InferhubAssistant(keyStore: _KeyStore('sk-x'), client: client);
    final result = await repo.ask(systemPrompt: 's', question: 'q');

    expect(result.failure, isA<AuthFailure>());
    expect(result.failure!.message, contains('ditolak'));
  });

  test('502 menjadi NetworkFailure dengan kode status', () async {
    final client = MockClient((_) async => http.Response('bad gateway', 502));
    final repo = InferhubAssistant(keyStore: _KeyStore('sk-x'), client: client);
    final result = await repo.ask(systemPrompt: 's', question: 'q');

    expect(result.failure, isA<NetworkFailure>());
    expect(result.failure!.message, contains('502'));
  });

  test('konten kosong menjadi LocalFailure, bukan jawaban hampa', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(_body('   ')), 200),
    );
    final repo = InferhubAssistant(keyStore: _KeyStore('sk-x'), client: client);
    final result = await repo.ask(systemPrompt: 's', question: 'q');

    expect(result.failure, isA<LocalFailure>());
    expect(result.answer, isNull);
  });

  test('badan bukan JSON menjadi LocalFailure', () async {
    final client = MockClient((_) async => http.Response('<html>', 200));
    final repo = InferhubAssistant(keyStore: _KeyStore('sk-x'), client: client);
    final result = await repo.ask(systemPrompt: 's', question: 'q');

    expect(result.failure, isA<LocalFailure>());
  });

  test('SocketException menjadi NetworkFailure', () async {
    final client = MockClient(
      (_) async => throw const SocketException('offline'),
    );
    final repo = InferhubAssistant(keyStore: _KeyStore('sk-x'), client: client);
    final result = await repo.ask(systemPrompt: 's', question: 'q');

    expect(result.failure, isA<NetworkFailure>());
    expect(result.failure!.message, contains('koneksi'));
  });
}
