import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/api_client.dart';
import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Satu-satunya tempat wiring fitur auth. Widget tidak pernah membuat
/// repository sendiri.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(tokenStoreProvider)),
);

final apiClientProvider = Provider(
  (ref) => buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  ),
);

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(authRepositoryProvider).hasSession();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    final failure = result.failure;
    state = failure != null
        ? AsyncError(failure, StackTrace.current)
        : const AsyncData(true);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidateSelf();
  }

  /// Bukti alur 401 -> refresh -> retry SEKALI. Tidak ada backend kampus,
  /// jadi yang dibuktikan: request tidak digandakan dan token dibersihkan
  /// ketika refresh ikut gagal.
  Future<String> simulateUnauthorized() async {
    final dio = ref.read(apiClientProvider);
    final repo = ref.read(authRepositoryProvider);
    try {
      await dio.get<dynamic>('/private/announcements');
      return 'sukses (200)';
    } on Object catch (e) {
      final stillLoggedIn = await repo.accessToken() != null;
      if (!stillLoggedIn) await logout();
      return stillLoggedIn
          ? 'refresh gagal, token masih ada: ${e.runtimeType}'
          : 'refresh gagal -> sesi dibersihkan (wajib login ulang)';
    }
  }
}
