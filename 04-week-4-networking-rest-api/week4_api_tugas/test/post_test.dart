// Unit test tanpa jaringan: parsing model + pemetaan error.
//
// Tidak ada HTTP sungguhan di file ini — tidak ada Dio yang dipanggil, hanya
// objek `DioException` yang dibuat manual dan dioper ke mapper.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api_tugas/data/models/post.dart';
import 'package:week4_api_tugas/data/network_errors.dart';

void main() {
  group('Post.fromJson aman null / tipe salah', () {
    test('JSON lengkap diparsing apa adanya', () {
      final post = Post.fromJson({
        'userId': 1,
        'id': 2,
        'title': 'Judul',
        'body': 'Isi',
      });
      expect(post.userId, 1);
      expect(post.id, 2);
      expect(post.title, 'Judul');
      expect(post.body, 'Isi');
    });

    test('hanya id -> field lain jatuh ke default, tidak melempar', () {
      final post = Post.fromJson({'id': 7});
      expect(post.id, 7);
      expect(post.userId, 0);
      expect(post.title, '');
      expect(post.body, '');
    });

    test('null eksplisit dan tipe salah tidak melempar', () {
      final post = Post.fromJson({
        'id': '42', // String angka
        'userId': null,
        'title': 123, // num
        'body': ['bukan', 'string'], // List -> fallback
      });
      expect(post.id, 42);
      expect(post.userId, 0);
      expect(post.title, '123');
      expect(post.body, '');
    });

    test('objek kosong menghasilkan Post default', () {
      expect(
        Post.fromJson(const {}),
        const Post(userId: 0, id: 0, title: '', body: ''),
      );
    });
  });

  group('friendlyErrorMessage', () {
    DioException err(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/posts'),
              statusCode: status,
            ),
    );

    test('connectionError menyebut tidak dapat terhubung', () {
      expect(
        friendlyErrorMessage(err(DioExceptionType.connectionError)),
        contains('terhubung'),
      );
    });

    test('timeout punya pesan sendiri, bukan pesan koneksi', () {
      final message = friendlyErrorMessage(
        err(DioExceptionType.connectionTimeout),
      );
      expect(message, contains('timeout'));
      expect(message, isNot(contains('Tidak dapat terhubung')));
    });

    test('badResponse 404 / 500 / 503 dipetakan ke pesan berbeda', () {
      expect(
        friendlyErrorMessage(err(DioExceptionType.badResponse, status: 404)),
        contains('404'),
      );
      expect(
        friendlyErrorMessage(err(DioExceptionType.badResponse, status: 500)),
        contains('server'),
      );
      expect(
        friendlyErrorMessage(err(DioExceptionType.badResponse, status: 503)),
        contains('tidak tersedia'),
      );
    });

    test('error non-jaringan tidak membocorkan detail teknis', () {
      final message = friendlyErrorMessage(ArgumentError('rahasia internal'));
      expect(message, contains('tak terduga'));
      expect(message, isNot(contains('rahasia')));
    });
  });
}
