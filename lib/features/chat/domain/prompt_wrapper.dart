class PromptWrapper {
  final Map<String, String> _responseCache = {};

  String? getCachedResponse(String userText, String language) {
    if (userText.trim().isEmpty) return null;
    return _responseCache[_cacheKey(userText, language)];
  }

  void cacheResponse(String userText, String language, String response) {
    if (userText.trim().isNotEmpty && response.trim().isNotEmpty) {
      _responseCache[_cacheKey(userText, language)] = response;
    }
  }

  String processPrompt(String userText, String selectedLanguage) {
    final cleanText = userText.trim();
    if (cleanText.isEmpty) return "";

    // 1. Detect Intent
    final lower = cleanText.toLowerCase();
    bool isTranslation = lower.startsWith("translate") || 
                         lower.contains("translation") || 
                         lower.startsWith("meaning of");

    if (isTranslation) {
      return _buildTranslationPrompt(cleanText, selectedLanguage);
    } else {
      return _buildChatPrompt(cleanText, selectedLanguage);
    }
  }

  String _buildTranslationPrompt(String text, String language) {
    // FIX: Removed invalid (?i) syntax. Using caseSensitive: false is safer.
    final regex = RegExp(r'(translate|translation|meaning of|to)', caseSensitive: false);
    String content = text.replaceAll(regex, '').trim();
    
    if (content.isEmpty) content = text;

    final scriptHint = _scriptHint(language);
    return """
<|system|>
You are a translator. Translate the text to $language. ${scriptHint}Output ONLY the translation. Do not add quotes, labels, or extra text.
<|user|>
Text: "$content"
Target: $language
<|assistant|>
""";
  }

  String _buildChatPrompt(String text, String language) {
    String langInstruction =
        "Answer in English. Respond directly in one reply. Do not ask follow-up questions. Do not include role labels (User/You/Vani).";
    
    if (language != "English") {
      final scriptHint = _scriptHint(language);
      langInstruction =
          "Answer in $language. ${scriptHint}Keep it short and respond directly. Do not include role labels (User/You/Vani).";
    }

    return """
<|system|>
You are Vani. $langInstruction
<|user|>
$text
<|assistant|>
""";
  }

  String _cacheKey(String userText, String language) {
    return '${language.toLowerCase().trim()}::${userText.trim().toLowerCase()}';
  }

  String _scriptHint(String language) {
    switch (language) {
      case "Hindi":
      case "Marathi":
        return "Use Devanagari script. ";
      case "Gujarati":
        return "Use Gujarati script. ";
      case "Tamil":
        return "Use Tamil script. ";
      default:
        return "";
    }
  }
}
