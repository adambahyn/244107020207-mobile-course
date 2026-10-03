import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
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
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}

/// Token FCM terpotong untuk halaman Debug (jangan tampilkan token penuh).
class FcmTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final fcmTokenProvider = NotifierProvider<FcmTokenNotifier, String?>(
  FcmTokenNotifier.new,
);

/// Jumlah request simulasi 401 untuk membuktikan refresh+retry berjalan.
class RefreshCountNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final refreshCountProvider = NotifierProvider<RefreshCountNotifier, int>(
  RefreshCountNotifier.new,
);
