import '../../../../core/failures.dart';
import '../entities/session.dart';

/// Kontrak domain auth. Implementasi (secure storage, HTTP) ada di data/.
/// Sukses/gagal eksplisit lewat record supaya exception tidak bocor ke UI.
abstract class AuthRepository {
  Future<bool> hasSession();

  Future<String?> accessToken();

  Future<({Session? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? access, Failure? failure})> refresh(String refreshToken);

  Future<void> logout();
}
