class Message {
  final String text;
  final bool isUser; // true = User (Right), false = AI (Left)
  final DateTime timestamp;

  Message({
    required this.text, 
    required this.isUser, 
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}