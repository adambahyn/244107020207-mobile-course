import '../../../../core/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';

/// Implementasi kontrak auth. Sesi masih mock (siap diganti Firebase Auth),
/// penyimpanan token nyata lewat [TokenStore].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._store, {
    this._latency = const Duration(milliseconds: 300),
  });

  final TokenStore _store;
  final Duration _latency;

  @override
  Future<bool> hasSession() async => await _store.readAccess() != null;

  @override
  Future<String?> accessToken() => _store.readAccess();

  @override
  Future<({Session? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    if (!email.contains('@') || password.length < 6) {
      return (
        session: null,
        failure: const AuthFailure('Email atau kata sandi tidak valid'),
      );
    }
    // Simulasi JWT header.payload.signature. Verifikasi nyata di server.
    final session = Session(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
    await _store.save(access: session.access, refresh: session.refresh);
    return (session: session, failure: null);
  }

  @override
  Future<({String? access, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    await Future<void>.delayed(_latency);
    if (refreshToken.isEmpty) {
      return (access: null, failure: const AuthFailure('Refresh token hilang'));
    }
    return (
      access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
      failure: null,
    );
  }

  @override
  Future<void> logout() => _store.clear();
}
