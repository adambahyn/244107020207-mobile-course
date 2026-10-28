import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import 'token_store.dart';

/// Dio dengan refresh otomatis: 401 -> tukar refresh -> ulangi request SEKALI.
/// Refresh ikut mati -> token dibersihkan sehingga guard route memaksa login.
Dio buildApiClient(TokenStore store, AuthRepository auth, {String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode != 401) return handler.next(e);
        // Cegah loop: request yang sudah pernah di-retry tidak diulang lagi.
        if (e.requestOptions.extra['retried'] == true) return handler.next(e);

        final refresh = await store.readRefresh();
        if (refresh == null || refresh.isEmpty) return handler.next(e);

        final renewed = await auth.refresh(refresh);
        if (renewed.failure != null) {
          await store.clear(); // refresh mati -> paksa login ulang
          return handler.next(e);
        }

        await store.save(access: renewed.access!, refresh: refresh);
        e.requestOptions
          ..headers['Authorization'] = 'Bearer ${renewed.access}'
          ..extra['retried'] = true;
        final retry = await dio.fetch<dynamic>(e.requestOptions);
        return handler.resolve(retry);
      },
    ),
  );

  return dio;
}
