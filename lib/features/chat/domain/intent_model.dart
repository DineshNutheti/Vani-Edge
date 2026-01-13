import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'intent.dart';

/// Naive Bayes text classifier trained from local intent samples.
class IntentModel {
  // Bag-of-words counts per intent (token -> count) for Naive Bayes.
  final Map<Intent, Map<String, int>> _wordCounts = {
    for (final intent in Intent.values) intent: {},
  };
  // Total token counts per intent for P(token|intent).
  final Map<Intent, int> _totalWords = {
    for (final intent in Intent.values) intent: 0,
  };
  // Sample counts per intent for P(intent).
  final Map<Intent, int> _docCounts = {
    for (final intent in Intent.values) intent: 0,
  };
  // Vocabulary size for Laplace smoothing across intents.
  final Set<String> _vocab = {};
  bool _trained = false;

  /// Trains the intent model from a JSON asset of {intent, text} samples.
  /// Input: asset path; Output: internal word/intent counts used by predict().
  Future<void> loadFromAssets(String path) async {
    if (_trained) {
      return;
    }
    final raw = await rootBundle.loadString(path);
    final data = jsonDecode(raw) as List<dynamic>;
    for (final entry in data) {
      final map = entry as Map<String, dynamic>;
      final intent = _intentFromString(map['intent'] as String);
      final text = (map['text'] as String).trim();
      _docCounts[intent] = (_docCounts[intent] ?? 0) + 1;
      // Tokenize and update counts for Naive Bayes training.
      for (final token in _tokenize(text)) {
        _vocab.add(token);
        final counts = _wordCounts[intent]!;
        counts[token] = (counts[token] ?? 0) + 1;
        _totalWords[intent] = (_totalWords[intent] ?? 0) + 1;
      }
    }
    _trained = true;
  }

  /// Returns the most likely intent and confidence for the given text.
  IntentResult predict(String text) {
    if (!_trained) {
      return const IntentResult(
        intent: Intent.chat,
        confidence: 0.0,
        scores: {},
      );
    }
    final tokens = _tokenize(text);
    if (tokens.isEmpty) {
      return const IntentResult(
        intent: Intent.chat,
        confidence: 0.0,
        scores: {},
      );
    }

    final totalDocs = _docCounts.values.fold<int>(0, (sum, v) => sum + v);
    final vocabSize = max(_vocab.length, 1);
    final Map<Intent, double> logScores = {};

    for (final intent in Intent.values) {
      // Compute log P(intent) + sum log P(token|intent) with Laplace smoothing.
      final prior = (_docCounts[intent] ?? 0) / max(totalDocs, 1);
      double logProb = log(prior + 1e-6);
      final totalWords = max(_totalWords[intent] ?? 0, 1);
      final counts = _wordCounts[intent]!;
      for (final token in tokens) {
        final count = counts[token] ?? 0;
        final prob = (count + 1) / (totalWords + vocabSize);
        logProb += log(prob);
      }
      logScores[intent] = logProb;
    }

    final maxLog = logScores.values.reduce(max);
    double sumExp = 0;
    final Map<Intent, double> scores = {};
    // Convert log scores to normalized probabilities (softmax).
    for (final entry in logScores.entries) {
      final score = exp(entry.value - maxLog);
      scores[entry.key] = score;
      sumExp += score;
    }

    Intent bestIntent = Intent.chat;
    double bestScore = -1;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestIntent = entry.key;
        bestScore = entry.value;
      }
    }

    final confidence = sumExp == 0 ? 0.0 : bestScore / sumExp;
    return IntentResult(intent: bestIntent, confidence: confidence, scores: scores);
  }

  Intent _intentFromString(String value) {
    switch (value.toLowerCase()) {
      case 'translate':
        return Intent.translate;
      case 'summarize':
        return Intent.summarize;
      case 'qna':
        return Intent.qna;
      case 'task':
        return Intent.task;
      case 'chat':
        return Intent.chat;
      default:
        return Intent.chat;
    }
  }

  // Unicode-aware cleanup keeps tokens consistent across languages.
  List<String> _tokenize(String text) {
    // Unicode-aware cleanup keeps tokens consistent across languages.
    final normalized = text.toLowerCase().replaceAll(RegExp(r'[\p{P}\p{S}]', unicode: true), ' ');
    return normalized
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }
}
