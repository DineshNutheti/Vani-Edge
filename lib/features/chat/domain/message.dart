import '../../../core/app_language.dart';

class Message {
  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.language,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AppLanguage language;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'language': AppLanguages.config(language).code,
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      language: AppLanguages.fromCode(json['language'] as String),
    );
  }
}
