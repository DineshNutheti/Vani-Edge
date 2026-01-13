/// Supported request intents used by the local model.
enum Intent {
  translate,
  summarize,
  qna,
  task,
  chat,
}

/// Classification output including confidence and per-intent scores.
class IntentResult {
  const IntentResult({
    required this.intent,
    required this.confidence,
    required this.scores,
  });

  final Intent intent;
  final double confidence;
  final Map<Intent, double> scores;
}
