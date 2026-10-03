import '../routes.dart';

/// Parsing murni RemoteMessage.data -> route. Dipisah supaya bisa diunit-test
/// tanpa Firebase.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] ?? '').toString().trim();
  if (raw.isEmpty) return Routes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}
