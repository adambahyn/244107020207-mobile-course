/// Failure domain: murni Dart, tanpa Flutter, Dio, SQLite, atau Firebase.
/// Presentation hanya menerima pesan yang sudah ramah pengguna.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
