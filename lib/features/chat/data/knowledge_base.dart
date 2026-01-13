import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/app_language.dart';

/// Single KB entry with keywords and localized answers.
class KnowledgeEntry {
  KnowledgeEntry({
    required this.id,
    required this.keywords,
    required this.answers,
  });

  final String id;
  final Map<AppLanguage, List<String>> keywords;
  final Map<AppLanguage, String> answers;

  String answerFor(AppLanguage language) {
    return answers[language] ?? answers[AppLanguage.english] ?? '';
  }
}

/// Loads and searches KB entries by token overlap.
class KnowledgeBase {
  final List<KnowledgeEntry> _entries = [];
  bool _loaded = false;

  /// Loads KB entries from a JSON asset once per app session.
  Future<void> loadFromAssets(String path) async {
    if (_loaded) {
      return;
    }
    // Load static KB entries once to avoid repeated asset I/O.
    final raw = await rootBundle.loadString(path);
    final data = jsonDecode(raw) as List<dynamic>;
    for (final entry in data) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;
      final keywordsByLang = <AppLanguage, List<String>>{};
      final rawKeywords = map['keywords'] as Map<String, dynamic>;
      for (final langEntry in rawKeywords.entries) {
        final language = AppLanguages.fromCode(langEntry.key);
        keywordsByLang[language] =
            (langEntry.value as List<dynamic>).map((e) => e.toString()).toList();
      }
      final answersByLang = <AppLanguage, String>{};
      final rawAnswers = map['answers'] as Map<String, dynamic>;
      for (final langEntry in rawAnswers.entries) {
        final language = AppLanguages.fromCode(langEntry.key);
        answersByLang[language] = langEntry.value.toString();
      }
      _entries.add(KnowledgeEntry(
        id: id,
        keywords: keywordsByLang,
        answers: answersByLang,
      ));
    }
    _loaded = true;
  }

  /// Returns the best matching answer for text in the given language, or null.
  String? lookup(String text, AppLanguage language) {
    if (_entries.isEmpty) {
      return null;
    }
    final tokens = _tokenize(text);
    if (tokens.isEmpty) {
      return null;
    }
    KnowledgeEntry? bestEntry;
    int bestScore = 0;
    for (final entry in _entries) {
      // Token overlap scoring selects the best matching answer per language.
      final keywords = entry.keywords[language] ?? entry.keywords[AppLanguage.english] ?? [];
      final score = tokens.where((token) => keywords.contains(token)).length;
      if (score > bestScore) {
        bestScore = score;
        bestEntry = entry;
      }
    }
    if (bestEntry == null || bestScore == 0) {
      return null;
    }
    return bestEntry.answerFor(language);
  }

  List<String> _tokenize(String text) {
    final normalized = text.toLowerCase().replaceAll(RegExp(r'[\p{P}\p{S}]', unicode: true), ' ');
    return normalized
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }
}
