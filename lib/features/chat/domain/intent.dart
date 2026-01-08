enum Intent {
  translate,
  summarize,
  qna,
  task,
  chat,
}

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
