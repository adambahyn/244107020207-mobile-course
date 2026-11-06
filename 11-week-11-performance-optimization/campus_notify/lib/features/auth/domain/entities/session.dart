/// Entity sesi login. Murni Dart: tanpa mapping, tanpa framework.
class Session {
  const Session({required this.access, required this.refresh});

  final String access;
  final String refresh;
}
