// Verifikasi provider + repository terhadap server nyata.
//
// Membuktikan bahwa AsyncNotifierProvider benar-benar menghasilkan AsyncData
// saat sukses dan AsyncError saat gagal — tanpa satu pun try/catch di provider.
//
// Jalankan: flutter test test_comment_provider_e2e.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/comment_provider.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/repositories/comment_repository.dart';

void main() {
  test('provider sukses -> AsyncData<List<Comment>>', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final comments = await readCommentsOnce(container, 1);

    expect(comments, isNotEmpty);
    expect(comments.every((c) => c.postId == 1), isTrue);
    // ignore: avoid_print
    print('OK AsyncData: ${comments.length} komentar untuk post 1');
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('provider gagal -> AsyncError otomatis (tanpa try/catch)', () async {
    final container = ProviderContainer(
      overrides: [
        // Repository palsu yang selalu melempar DioException 404, sehingga
        // tidak perlu jaringan untuk menguji jalur error.
        commentRepositoryProvider.overrideWith((ref) => _ThrowingRepository()),
      ],
    );
    addTearDown(container.dispose);

    Object? caught;
    try {
      await readCommentsOnce(container, 1);
    } catch (e) {
      caught = e;
    }

    // Error dari repository sampai utuh ke pemanggil sebagai AsyncError.
    expect(caught, isA<DioException>());
    expect((caught as DioException).response?.statusCode, 404);

    // State provider memang AsyncError, dan pesannya ramah pengguna.
    final state = container.read(commentListProvider(1));
    expect(state.hasError, isTrue);
    expect(commentErrorMessage(state.error), contains('404'));

    // ignore: avoid_print
    print('OK AsyncError: ${commentErrorMessage(state.error)}');
  });

  test('postId <= 0 -> AsyncError dari validasi argumen', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Object? caught;
    try {
      await readCommentsOnce(container, 0);
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<ArgumentError>());
    // ignore: avoid_print
    print('OK validasi argumen: $caught');
  });
}

/// Repository palsu: selalu gagal dengan DioException 404.
class _ThrowingRepository implements CommentRepository {
  @override
  Future<List<Comment>> fetchComments(int postId) async {
    final options = RequestOptions(path: '/comments');
    throw DioException.badResponse(
      statusCode: 404,
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 404),
    );
  }
}
