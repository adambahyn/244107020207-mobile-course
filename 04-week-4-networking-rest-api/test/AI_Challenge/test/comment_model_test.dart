// Unit test untuk [Comment.fromJson].
//
// Fokus: memastikan parsing tetap aman (tidak melempar exception) ketika
// server mengirim JSON yang tidak lengkap — field hilang, null, atau
// bertipe beda. Ini penting karena satu field rusak tidak boleh membuat
// seluruh halaman crash.
//
// Jalankan: flutter test test/comment_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment.fromJson - JSON lengkap', () {
    test('membaca semua field dengan benar', () {
      // Contoh persis seperti response JSONPlaceholder.
      final comment = Comment.fromJson(const {
        'postId': 1,
        'id': 5,
        'name': 'id labore ex et quam laborum',
        'email': 'Eliseo@gardner.biz',
        'body': 'laudantium enim quasi est quidem magnam',
      });

      expect(comment.postId, 1);
      expect(comment.id, 5);
      expect(comment.name, 'id labore ex et quam laborum');
      expect(comment.email, 'Eliseo@gardner.biz');
      expect(comment.body, 'laudantium enim quasi est quidem magnam');
    });
  });

  group('Comment.fromJson - field hilang (nullable-safe)', () {
    test('JSON kosong menghasilkan nilai default, bukan exception', () {
      // Skenario: server mengirim objek kosong / body tidak sesuai kontrak.
      final comment = Comment.fromJson(const <String, dynamic>{});

      expect(comment.postId, 0); // angka -> fallback 0
      expect(comment.id, 0);
      expect(comment.name, ''); // string -> fallback ''
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('hanya sebagian field yang ada, sisanya terisi default', () {
      // Skenario: hanya `id` yang dikirim (mis. response terpotong).
      final comment = Comment.fromJson(const {'id': 7, 'name': 'Nama saja'});

      expect(comment.id, 7);
      expect(comment.name, 'Nama saja');
      expect(comment.postId, 0, reason: 'postId hilang -> 0');
      expect(comment.email, '', reason: 'email hilang -> string kosong');
      expect(comment.body, '', reason: 'body hilang -> string kosong');
    });

    test('field bernilai null eksplisit juga aman', () {
      // Skenario: backend mengirim key-nya tetapi value-nya null.
      final comment = Comment.fromJson(const {
        'postId': null,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      });

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('tipe data "salah" tetap dikonversi, tidak melempar TypeError', () {
      // Skenario: backend mengirim angka sebagai String, dan angka pecahan.
      final comment = Comment.fromJson(const {
        'postId': '3', // String angka -> 3
        'id': 4.0, // double -> 4
        'name': 123, // num -> "123"
        'email': true, // bool -> "true"
        // body diisi Map: tipe yang tidak masuk akal -> string kosong.
        'body': {'nested': 'value'},
      });

      expect(comment.postId, 3);
      expect(comment.id, 4);
      expect(comment.name, '123');
      expect(comment.email, 'true');
      expect(comment.body, '', reason: 'Map bukan teks -> fallback kosong');
    });

    test('String yang bukan angka tetap memakai fallback 0', () {
      final comment = Comment.fromJson(const {
        'postId': 'bukan-angka',
        'id': '',
      });

      expect(comment.postId, 0);
      expect(comment.id, 0);
    });
  });

  group('Comment - perilaku tambahan', () {
    test('toJson mengembalikan data yang bisa diparse ulang', () {
      const original = Comment(
        postId: 2,
        id: 9,
        name: 'A',
        email: 'a@b.c',
        body: 'isi',
      );

      expect(Comment.fromJson(original.toJson()), equals(original));
    });

    test('copyWith hanya mengubah field yang diberikan', () {
      const original = Comment(
        postId: 2,
        id: 9,
        name: 'A',
        email: 'a@b.c',
        body: 'isi',
      );

      final copy = original.copyWith(name: 'B');

      expect(copy.name, 'B');
      expect(copy.postId, original.postId);
      expect(copy.id, original.id);
      expect(copy.email, original.email);
      expect(copy.body, original.body);
    });
  });
}
