import '../../../core/app_language.dart';

/// Conversation message stored in history and shown in UI.
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

  /// Serializes for persistence in shared preferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'language': AppLanguages.config(language).code,
      };

  /// Hydrates from persisted JSON.
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
