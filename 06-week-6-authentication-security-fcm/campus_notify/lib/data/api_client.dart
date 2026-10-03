import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// Dio dengan refresh otomatis: 401 -> tukar refresh -> ulangi request SEKALI.
/// Refresh ikut mati -> clear() sehingga guard route memaksa login ulang.
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

        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          e.requestOptions
            ..headers['Authorization'] = 'Bearer $renewed'
            ..extra['retried'] = true;
          final retry = await dio.fetch<dynamic>(e.requestOptions);
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh mati -> paksa login ulang
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
