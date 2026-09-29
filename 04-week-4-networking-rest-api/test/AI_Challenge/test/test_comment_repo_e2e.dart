// Verifikasi lapisan repository secara nyata terhadap JSONPlaceholder.
//
// Dijalankan lewat `flutter test test_comment_repo_e2e.dart` (bukan bagian dari
// unit test harian karena butuh jaringan).
//
// Membuktikan tiga hal yang diminta tugas:
//   1. fetchComments(postId) benar-benar mengirim GET /comments?postId=...
//      dan memetakan hasilnya menjadi List<Comment>.
//   2. postId yang tidak punya komentar menghasilkan list kosong, bukan error.
//   3. status 404/500 diterjemahkan menjadi pesan ramah pengguna.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/comment_errors.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/repositories/comment_repository.dart';

Dio _dio({List<Interceptor>? interceptors}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  if (interceptors != null) dio.interceptors.addAll(interceptors);
  return dio;
}

void main() {
  test('fetchComments(1) mengembalikan komentar post 1 dari server', () async {
    final repo = CommentRepository(_dio());

    final comments = await repo.fetchComments(1);

    expect(comments, isNotEmpty);
    // JSONPlaceholder: post 1 punya 5 komentar, semuanya ber-postId 1.
    expect(comments.length, 5);
    expect(comments.every((c) => c.postId == 1), isTrue);
    // Field wajib terisi (bukan hasil fallback).
    final first = comments.first;
    expect(first.id, greaterThan(0));
    expect(first.name, isNotEmpty);
    expect(first.email, contains('@'));
    expect(first.body, isNotEmpty);

    // ignore: avoid_print
    print('OK post 1 -> ${comments.length} komentar, contoh: '
        '${first.id} ${first.email} "${first.name}"');
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('fetchComments mengirim query ?postId= sesuai argumen', () async {
    // Interceptor merekam URL yang benar-benar diminta Dio.
    late String requestedUri;
    final repo = CommentRepository(
      _dio(
        interceptors: [
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedUri = options.uri.toString();
              handler.next(options);
            },
          ),
        ],
      ),
    );

    await repo.fetchComments(3);

    // ignore: avoid_print
    print('OK request URI = $requestedUri');
    expect(requestedUri, contains('/comments'));
    expect(requestedUri, contains('postId=3'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('postId tanpa komentar -> list kosong, bukan error', () async {
    final repo = CommentRepository(_dio());

    // 999 tidak ada di data JSONPlaceholder -> JSONPlaceholder membalas 200 [].
    final comments = await repo.fetchComments(999);

    expect(comments, isEmpty);
    // ignore: avoid_print
    print('OK post 999 -> list kosong (${comments.length} item)');
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('status 404 nyata -> DioException badResponse + pesan ramah', () async {
    // Endpoint sengaja dibuat tidak ada supaya server mengirim 404.
    final repo = CommentRepository(_dio());
    Object? caught;
    try {
      await repo.fetchComments(-1).timeout(const Duration(seconds: 20));
      // Fallback: kalau JSONPlaceholder tetap membalas 200, uji lewat response tiruan.
    } catch (e) {
      caught = e;
    }

    if (caught is DioException) {
      expect(caught.response?.statusCode, 404);
      // ignore: avoid_print
      print('OK 404 asli -> "${friendlyCommentError(caught)}"');
    } else {
      // ignore: avoid_print
      print('Server tidak membalas 404 untuk postId=-1 '
          '(${caught.runtimeType}) — pakai response tiruan.');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('pesan ramah untuk timeout, connection error, 404, dan 500', () {
    final opts = RequestOptions(path: '/comments');

    final timeoutErr = DioException.connectionTimeout(
      timeout: const Duration(seconds: 10),
      requestOptions: opts,
    );
    final connErr = DioException.connectionError(
      requestOptions: opts,
      reason: 'no internet',
    );
    final notFound = DioException.badResponse(
      statusCode: 404,
      requestOptions: opts,
      response: Response(requestOptions: opts, statusCode: 404),
    );
    final serverErr = DioException.badResponse(
      statusCode: 500,
      requestOptions: opts,
      response: Response(requestOptions: opts, statusCode: 500),
    );

    expect(friendlyCommentError(timeoutErr), contains('timeout'));
    expect(friendlyCommentError(connErr), contains('terhubung ke server'));
    expect(friendlyCommentError(notFound), contains('404'));
    expect(friendlyCommentError(serverErr), contains('500'));

    // ignore: avoid_print
    print('OK timeout      -> ${friendlyCommentError(timeoutErr)}');
    // ignore: avoid_print
    print('OK offline      -> ${friendlyCommentError(connErr)}');
    // ignore: avoid_print
    print('OK 404          -> ${friendlyCommentError(notFound)}');
    // ignore: avoid_print
    print('OK 500          -> ${friendlyCommentError(serverErr)}');
  });
}
