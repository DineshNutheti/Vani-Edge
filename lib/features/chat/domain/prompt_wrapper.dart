import '../../../core/app_language.dart';
import '../data/response_cache.dart';
import 'intent.dart';
import 'intent_model.dart';
import 'local_model.dart';

/// Wrapper output with response metadata for debugging and UI.
class WrappedResponse {
  const WrappedResponse({
    required this.response,
    required this.intentResult,
    required this.usedCache,
    required this.attempts,
  });

  final ModelResponse response;
  final IntentResult intentResult;
  final bool usedCache;
  final int attempts;
}

/// Orchestrates intent detection, constraints, caching, and validation.
class PromptWrapper {
  PromptWrapper({
    required IntentModel intentModel,
    required LocalModel localModel,
    required ResponseCache cache,
  })  : _intentModel = intentModel,
        _localModel = localModel,
        _cache = cache,
        _validator = OutputValidator();

  final IntentModel _intentModel;
  final LocalModel _localModel;
  final ResponseCache _cache;
  final OutputValidator _validator;

  /// End-to-end wrapper: detect intent, enforce constraints, retry, and cache.
  /// Input: raw user text + language; Output: response + metadata.
  Future<WrappedResponse> handle(String text, AppLanguage language) async {
    final normalized = _normalize(text);
    final intentResult = _intentModel.predict(normalized);
    final request = _buildRequest(intentResult.intent, language, text, strict: false);
    final cacheKey = _cacheKey(language, intentResult.intent, normalized);

    // Cache avoids repeated model work and keeps identical inputs consistent.
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return WrappedResponse(
        response: ModelResponse(intent: intentResult.intent, text: cached),
        intentResult: intentResult,
        usedCache: true,
        attempts: 1,
      );
    }

    var response = _localModel.generate(request);
    var attempts = 1;
    // Validate format/language; retry once with stricter constraints.
    if (!_validator.isValid(response.text, language, request.maxWords)) {
      final retryRequest = _buildRequest(
        intentResult.intent,
        language,
        text,
        strict: true,
      );
      response = _localModel.generate(retryRequest);
      attempts = 2;
    }

    // Persist response for future identical requests.
    await _cache.set(cacheKey, response.text);
    return WrappedResponse(
      response: response,
      intentResult: intentResult,
      usedCache: false,
      attempts: attempts,
    );
  }

  ModelRequest _buildRequest(
    Intent intent,
    AppLanguage language,
    String text, {
    required bool strict,
  }) {
    // Per-intent word caps keep outputs compact and predictable.
    final maxWords = switch (intent) {
      Intent.translate => 30,
      Intent.summarize => 40,
      Intent.qna => 35,
      Intent.task => 45,
      Intent.chat => 20,
    };
    return ModelRequest(
      intent: intent,
      language: language,
      userText: text,
      maxWords: maxWords,
      strict: strict,
    );
  }

  String _cacheKey(AppLanguage language, Intent intent, String normalizedText) {
    return '${AppLanguages.config(language).code}::${intent.name}::$normalizedText';
  }

  String _normalize(String text) {
    return text.trim().toLowerCase();
  }
}

/// Validates response text length and language script.
class OutputValidator {
  bool isValid(String text, AppLanguage language, int maxWords) {
    if (text.trim().isEmpty) {
      return false;
    }
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length > maxWords + 10) {
      return false;
    }
    // Ensure output appears in the selected language script.
    if (!_containsLanguageScript(text, language)) {
      return false;
    }
    return true;
  }

  bool _containsLanguageScript(String text, AppLanguage language) {
    if (language == AppLanguage.english) {
      return true;
    }
    final runeList = text.runes.toList();
    for (final rune in runeList) {
      if (_matchesScript(rune, language)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesScript(int rune, AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
      case AppLanguage.marathi:
        return rune >= 0x0900 && rune <= 0x097F;
      case AppLanguage.tamil:
        return rune >= 0x0B80 && rune <= 0x0BFF;
      case AppLanguage.gujarati:
        return rune >= 0x0A80 && rune <= 0x0AFF;
      case AppLanguage.english:
        return true;
    }
  }
}
