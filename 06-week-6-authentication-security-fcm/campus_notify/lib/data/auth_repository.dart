/// Mock auth yang siap diganti Firebase Auth.
/// Titik ganti: method [login] -> FirebaseAuth.instance.signInWithEmailAndPassword.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

class AuthRepository {
  AuthRepository({Duration? latency})
    : _latency = latency ?? const Duration(milliseconds: 300);

  final Duration _latency;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_latency);
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Email atau kata sandi tidak valid');
    }
    // Simulasi JWT header.payload.signature. Di produksi JANGAN parse manual —
    // verifikasi dilakukan di server.
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(_latency);
    if (refreshToken.isEmpty) throw Exception('Refresh token hilang');
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
