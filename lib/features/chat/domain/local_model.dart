import '../../../core/app_language.dart';
import '../data/knowledge_base.dart';
import 'intent.dart';

class ModelRequest {
  ModelRequest({
    required this.intent,
    required this.language,
    required this.userText,
    required this.maxWords,
    this.strict = false,
  });

  final Intent intent;
  final AppLanguage language;
  final String userText;
  final int maxWords;
  final bool strict;
}

class ModelResponse {
  const ModelResponse({required this.intent, required this.text});

  final Intent intent;
  final String text;
}

class LocalModel {
  LocalModel({required KnowledgeBase knowledgeBase}) : _knowledgeBase = knowledgeBase;

  // Keyword-based knowledge base used for deterministic QnA.
  final KnowledgeBase _knowledgeBase;

  ModelResponse generate(ModelRequest request) {
    final responses = ResponseStrings(request.language);
    switch (request.intent) {
      case Intent.translate:
        return ModelResponse(
          intent: request.intent,
          text: _translate(request, responses),
        );
      case Intent.summarize:
        return ModelResponse(
          intent: request.intent,
          text: _summarize(request, responses),
        );
      case Intent.qna:
        return ModelResponse(
          intent: request.intent,
          text: _answer(request, responses),
        );
      case Intent.task:
        return ModelResponse(
          intent: request.intent,
          text: _task(request, responses),
        );
      case Intent.chat:
        return ModelResponse(
          intent: request.intent,
          text: _chat(request, responses),
        );
    }
  }

  String _translate(ModelRequest request, ResponseStrings responses) {
    // Glossary lookup is fast and stable; no generative translation.
    if (request.strict) {
      return responses.translationFallback;
    }
    final normalized = request.userText.toLowerCase().trim();
    final translated = _translationGlossary[normalized]?[request.language];
    if (translated != null) {
      return '${responses.translationPrefix} $translated';
    }
    return responses.translationFallback;
  }

  String _summarize(ModelRequest request, ResponseStrings responses) {
    // Simple extractive summary: first two sentences when input is long enough.
    final text = request.userText.trim();
    if (text.split(RegExp(r'\s+')).length < 8) {
      return responses.summaryFallback;
    }
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    final summary = sentences.take(2).join(' ').trim();
    final limited = _limitWords(summary, request.maxWords);
    return '${responses.summaryPrefix} $limited';
  }

  String _answer(ModelRequest request, ResponseStrings responses) {
    // Token overlap scoring against the knowledge base.
    final match = _knowledgeBase.lookup(request.userText, request.language);
    if (match != null) {
      return '${responses.shortAnswer} $match';
    }
    return responses.qnaFallback;
  }

  String _task(ModelRequest request, ResponseStrings responses) {
    // Structured steps keep responses short and deterministic.
    if (request.strict) {
      return responses.taskFallback;
    }
    final goal = request.userText.trim();
    if (goal.isEmpty) {
      return responses.taskFallback;
    }
    final steps = <String>[
      _limitWords(goal, 10),
      'Break it into smaller tasks',
      'Complete one step at a time',
    ];
    final localizedSteps = _localizeSteps(steps, request.language);
    return '${responses.stepsPrefix}\n${_formatSteps(localizedSteps)}';
  }

  List<String> _localizeSteps(List<String> steps, AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return [
          'लक्ष्य स्पष्ट करें: ${steps.first}',
          'इसे छोटे कार्यों में तोड़ें',
          'एक-एक कदम पूरा करें',
        ];
      case AppLanguage.marathi:
        return [
          'उद्दिष्ट स्पष्ट करा: ${steps.first}',
          'लहान कामांमध्ये विभागा',
          'एकावेळी एक पाऊल पूर्ण करा',
        ];
      case AppLanguage.tamil:
        return [
          'நோக்கத்தை தெளிவாக்கு: ${steps.first}',
          'சிறிய பணிகளாக பிரி',
          'ஒரு படியாக முடி',
        ];
      case AppLanguage.gujarati:
        return [
          'લક્ષ્ય સ્પષ્ટ કરો: ${steps.first}',
          'તેને નાના કામોમાં વહેંચો',
          'એક પગલું કરીને પૂર્ણ કરો',
        ];
      case AppLanguage.english:
        return [
          'Clarify the goal: ${steps.first}',
          'Break it into smaller tasks',
          'Finish one step at a time',
        ];
    }
  }

  String _formatSteps(List<String> steps) {
    return List.generate(steps.length, (i) => '${i + 1}. ${steps[i]}').join('\n');
  }

  String _limitWords(String text, int maxWords) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maxWords) {
      return text;
    }
    return words.take(maxWords).join(' ') + '...';
  }

  String _chat(ModelRequest request, ResponseStrings responses) {
    final raw = request.userText.trim();
    if (raw.isEmpty) {
      return responses.chatGreeting;
    }
    final normalized = raw.toLowerCase();
    final language = request.language;

    final greetingTokens = _greetingTokens[language] ?? _greetingTokens[AppLanguage.english]!;
    if (_containsAny(normalized, greetingTokens)) {
      final greetings = _chatGreetings[language] ?? _chatGreetings[AppLanguage.english]!;
      return _selectDeterministic(greetings, normalized);
    }

    final thanksTokens = _thanksTokens[language] ?? _thanksTokens[AppLanguage.english]!;
    if (_containsAny(normalized, thanksTokens)) {
      final replies = _thanksReplies[language] ?? _thanksReplies[AppLanguage.english]!;
      return _selectDeterministic(replies, normalized);
    }

    final name = _extractName(raw, language);
    if (name != null) {
      return _formatNameResponse(name, language);
    }

    final followups = _chatFollowups[language] ?? _chatFollowups[AppLanguage.english]!;
    return _selectDeterministic(followups, normalized);
  }

  bool _containsAny(String text, List<String> tokens) {
    for (final token in tokens) {
      if (text.contains(token)) {
        return true;
      }
    }
    return false;
  }

  String _selectDeterministic(List<String> options, String seedText) {
    if (options.isEmpty) {
      return seedText;
    }
    // Stable selection ensures same input gets the same response.
    final hash = seedText.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final index = hash % options.length;
    return options[index];
  }

  String? _extractName(String text, AppLanguage language) {
    // Lightweight pattern matching for "my name is" style utterances.
    final pattern = switch (language) {
      AppLanguage.english => RegExp(r"(?:my name is|i am|i'm)\s+([\p{L}]+)", caseSensitive: false, unicode: true),
      AppLanguage.hindi => RegExp(r"(?:मेरा नाम|मेरा नाम है)\s+([\p{L}]+)", unicode: true),
      AppLanguage.marathi => RegExp(r"(?:माझं नाव|माझे नाव)\s+([\p{L}]+)", unicode: true),
      AppLanguage.tamil => RegExp(r"(?:என் பெயர்)\s+([\p{L}]+)", unicode: true),
      AppLanguage.gujarati => RegExp(r"(?:મારું નામ)\s+([\p{L}]+)", unicode: true),
    };
    final match = pattern.firstMatch(text);
    if (match == null || match.groupCount < 1) {
      return null;
    }
    final candidate = match.group(1) ?? '';
    if (!_isValidName(candidate)) {
      return null;
    }
    return candidate;
  }

  bool _isValidName(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 24) {
      return false;
    }
    return RegExp(r'^[\\p{L}][\\p{L}\\-]*$', unicode: true).hasMatch(trimmed);
  }

  String _formatNameResponse(String name, AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'Nice to meet you, $name. How can I help?';
      case AppLanguage.hindi:
        return 'आपसे मिलकर अच्छा लगा, $name. मैं कैसे मदद करूं?';
      case AppLanguage.marathi:
        return 'भेटून आनंद झाला, $name. मी कशी मदत करू?';
      case AppLanguage.tamil:
        return 'உங்களை சந்தித்ததில் மகிழ்ச்சி, $name. நான் எப்படி உதவலாம்?';
      case AppLanguage.gujarati:
        return 'મળી ને આનંદ થયો, $name. હું કેવી રીતે મદદ કરું?';
    }
  }
}

const Map<String, Map<AppLanguage, String>> _translationGlossary = {
  'good morning': {
    AppLanguage.english: 'Good morning',
    AppLanguage.hindi: 'सुप्रभात',
    AppLanguage.marathi: 'शुभ सकाळ',
    AppLanguage.tamil: 'காலை வணக்கம்',
    AppLanguage.gujarati: 'સુપ્રભાત',
  },
  'thank you': {
    AppLanguage.english: 'Thank you',
    AppLanguage.hindi: 'धन्यवाद',
    AppLanguage.marathi: 'धन्यवाद',
    AppLanguage.tamil: 'நன்றி',
    AppLanguage.gujarati: 'આભાર',
  },
  'how are you': {
    AppLanguage.english: 'How are you?',
    AppLanguage.hindi: 'आप कैसे हैं?',
    AppLanguage.marathi: 'तुम कसे आहात?',
    AppLanguage.tamil: 'நீங்கள் எப்படி இருக்கிறீர்கள்?',
    AppLanguage.gujarati: 'તમે કેમ છો?',
  },
  'what can you do': {
    AppLanguage.english: 'What can you do?',
    AppLanguage.hindi: 'तुम क्या कर सकते हो?',
    AppLanguage.marathi: 'तुम काय करू शकता?',
    AppLanguage.tamil: 'நீ என்ன செய்ய முடியும்?',
    AppLanguage.gujarati: 'તમે શું કરી શકો?',
  },
};

const Map<AppLanguage, List<String>> _chatGreetings = {
  AppLanguage.english: [
    'Hello! How can I help today?',
    'Hi there! What would you like to do?',
    'Hey! Need a summary, translation, or steps?',
  ],
  AppLanguage.hindi: [
    'नमस्ते! आज मैं कैसे मदद करूं?',
    'हैलो! आप क्या करना चाहते हैं?',
    'मैं मदद के लिए हूँ—सारांश, अनुवाद या कदम बताने को कहें।',
  ],
  AppLanguage.marathi: [
    'नमस्कार! मी कशी मदत करू?',
    'हॅलो! तुम्हाला काय हवे आहे?',
    'मी मदतीसाठी आहे—सारांश, भाषांतर, किंवा पायऱ्या.',
  ],
  AppLanguage.tamil: [
    'வணக்கம்! இன்று நான் எப்படி உதவலாம்?',
    'ஹாய்! நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?',
    'நான் உதவ தயாராக இருக்கிறேன்—சுருக்கம், மொழிபெயர்ப்பு, படிகள்.',
  ],
  AppLanguage.gujarati: [
    'નમસ્તે! આજે હું કેવી રીતે મદદ કરી શકું?',
    'હેલો! તમે શું કરવા માંગો છો?',
    'હું મદદ માટે છું—સારાંશ, અનુવાદ, પગલાં.',
  ],
};

const Map<AppLanguage, List<String>> _chatFollowups = {
  AppLanguage.english: [
    'Tell me what you need, and I will keep it short.',
    'I can summarize, translate, or list steps. What do you want to do?',
    'Share a goal and I will break it into steps.',
  ],
  AppLanguage.hindi: [
    'बताइए, आपको किस चीज़ में मदद चाहिए? मैं संक्षेप में जवाब दूंगा।',
    'मैं सारांश, अनुवाद या कदम बता सकता हूँ। आप क्या करना चाहते हैं?',
    'लक्ष्य बताइए, मैं उसे कदमों में बांट दूंगा।',
  ],
  AppLanguage.marathi: [
    'तुम्हाला कशात मदत हवी आहे? मी संक्षेपात सांगतो.',
    'मी सारांश, भाषांतर किंवा पायऱ्या देऊ शकतो. तुम्हाला काय हवे?',
    'उद्दिष्ट सांगा, मी ते टप्प्यांत विभागतो.',
  ],
  AppLanguage.tamil: [
    'உங்களுக்கு என்ன உதவி வேண்டும்? நான் சுருக்கமாக பதில் சொல்கிறேன்.',
    'நான் சுருக்கம், மொழிபெயர்ப்பு அல்லது படிகளை தர முடியும். என்ன செய்ய வேண்டும்?',
    'நோக்கத்தை சொல்லுங்கள், அதை படிகளாக பிரிக்கிறேன்.',
  ],
  AppLanguage.gujarati: [
    'તમે શું મદદ જોઈએ છે તે કહો, હું સંક્ષેપમાં કહીશ.',
    'હું સારાંશ, અનુવાદ અથવા પગલાં આપી શકું છું. તમને શું કરવું છે?',
    'તમારું લક્ષ્ય કહો, હું તેને પગલાંમાં વહેંચી દઈશ.',
  ],
};

const Map<AppLanguage, List<String>> _thanksReplies = {
  AppLanguage.english: [
    'You are welcome! Anything else?',
    'Glad to help. Want another task?',
  ],
  AppLanguage.hindi: [
    'आपका स्वागत है! और कुछ चाहिए?',
    'खुशी हुई मदद करके। और कुछ करना है?',
  ],
  AppLanguage.marathi: [
    'स्वागत आहे! अजून काही हवे का?',
    'मदत करून आनंद झाला. आणखी काही करायचे का?',
  ],
  AppLanguage.tamil: [
    'பரவாயில்லை! வேறு ஏதாவது வேண்டுமா?',
    'உதவியது சந்தோஷம். இன்னொரு வேலை வேண்டுமா?',
  ],
  AppLanguage.gujarati: [
    'આપનું સ્વાગત છે! બીજું કંઈ જોઈએ?',
    'મદદ કરીને આનંદ થયો. બીજું કામ કરવું છે?',
  ],
};

const Map<AppLanguage, List<String>> _greetingTokens = {
  AppLanguage.english: ['hello', 'hi', 'hey', 'namaste'],
  AppLanguage.hindi: ['नमस्ते', 'हैलो', 'हाय', 'नमस्कार'],
  AppLanguage.marathi: ['नमस्कार', 'हॅलो', 'हाय'],
  AppLanguage.tamil: ['வணக்கம்', 'ஹாய்', 'ஹலோ'],
  AppLanguage.gujarati: ['નમસ્તે', 'હેલો', 'હાય'],
};

const Map<AppLanguage, List<String>> _thanksTokens = {
  AppLanguage.english: ['thanks', 'thank you'],
  AppLanguage.hindi: ['धन्यवाद', 'शुक्रिया'],
  AppLanguage.marathi: ['धन्यवाद', 'आभार'],
  AppLanguage.tamil: ['நன்றி'],
  AppLanguage.gujarati: ['આભાર', 'ધન્યવાદ'],
};
