import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'repositories/post_repository.dart';

/// Dio tunggal untuk seluruh aplikasi.
///
/// Satu-satunya provider yang membuat koneksi. Karena repository mengambil Dio
/// dari sini, test cukup meng-override [postRepositoryProvider] dan
/// `dioProvider` tidak pernah di-resolve — tidak ada HTTP sungguhan.
final dioProvider = Provider<Dio>((ref) => createDio());

/// Repository tunggal. Titik ganti implementasi (fake di test, cache lokal
/// nanti) tanpa menyentuh satu pun widget.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);
