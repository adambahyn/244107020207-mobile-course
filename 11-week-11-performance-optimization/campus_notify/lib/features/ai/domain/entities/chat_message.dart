/// Percakapan asisten: peran pengirim dan teksnya. Murni Dart.
enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final ChatRole role;
  final String text;

  bool get isUser => role == ChatRole.user;
}
