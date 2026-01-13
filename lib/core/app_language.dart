import 'package:flutter/material.dart';

/// Supported UI and speech languages in the app.
enum AppLanguage {
  english,
  hindi,
  marathi,
  tamil,
  gujarati,
}

/// Immutable language configuration used by UI, STT, and TTS layers.
class AppLanguageConfig {
  const AppLanguageConfig({
    required this.language,
    required this.code,
    required this.displayName,
    required this.locale,
    required this.sttLocaleId,
    required this.ttsLocaleId,
  });

  final AppLanguage language;
  final String code;
  final String displayName;
  final Locale locale;
  final String sttLocaleId;
  final String ttsLocaleId;
}

/// Helpers for language config lookup and normalization.
class AppLanguages {
  /// Ordered list used in the language dropdown.
  static const List<AppLanguage> all = [
    AppLanguage.english,
    AppLanguage.hindi,
    AppLanguage.marathi,
    AppLanguage.tamil,
    AppLanguage.gujarati,
  ];

  static const Map<AppLanguage, AppLanguageConfig> configs = {
    AppLanguage.english: AppLanguageConfig(
      language: AppLanguage.english,
      code: 'en',
      displayName: 'English',
      locale: Locale('en'),
      sttLocaleId: 'en_IN',
      ttsLocaleId: 'en-IN',
    ),
    AppLanguage.hindi: AppLanguageConfig(
      language: AppLanguage.hindi,
      code: 'hi',
      displayName: 'हिंदी',
      locale: Locale('hi'),
      sttLocaleId: 'hi_IN',
      ttsLocaleId: 'hi-IN',
    ),
    AppLanguage.marathi: AppLanguageConfig(
      language: AppLanguage.marathi,
      code: 'mr',
      displayName: 'मराठी',
      locale: Locale('mr'),
      sttLocaleId: 'mr_IN',
      ttsLocaleId: 'mr-IN',
    ),
    AppLanguage.tamil: AppLanguageConfig(
      language: AppLanguage.tamil,
      code: 'ta',
      displayName: 'தமிழ்',
      locale: Locale('ta'),
      sttLocaleId: 'ta_IN',
      ttsLocaleId: 'ta-IN',
    ),
    AppLanguage.gujarati: AppLanguageConfig(
      language: AppLanguage.gujarati,
      code: 'gu',
      displayName: 'ગુજરાતી',
      locale: Locale('gu'),
      sttLocaleId: 'gu_IN',
      ttsLocaleId: 'gu-IN',
    ),
  };

  // Central lookup for STT/TTS locale IDs and display labels.
  /// Single source of truth for locale + STT/TTS IDs used by UI and speech.
  static AppLanguageConfig config(AppLanguage language) => configs[language]!;

  /// Maps a language code (en/hi/...) to AppLanguage.
  static AppLanguage fromCode(String code) {
    for (final config in configs.values) {
      if (config.code == code) {
        return config.language;
      }
    }
    return AppLanguage.english;
  }

  /// Uses locale languageCode to map to AppLanguage.
  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}

/// UI copy by language for visible strings.
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  static const Map<String, Map<AppLanguage, String>> _strings = {
    'appTitle': {
      AppLanguage.english: 'Vani Edge',
      AppLanguage.hindi: 'वाणी एज',
      AppLanguage.marathi: 'वाणी एज',
      AppLanguage.tamil: 'வாணி எட்ஜ்',
      AppLanguage.gujarati: 'વાણી એજ',
    },
    'selectLanguage': {
      AppLanguage.english: 'Language',
      AppLanguage.hindi: 'भाषा',
      AppLanguage.marathi: 'भाषा',
      AppLanguage.tamil: 'மொழி',
      AppLanguage.gujarati: 'ભાષા',
    },
    'tapToSpeak': {
      AppLanguage.english: 'Tap mic and speak',
      AppLanguage.hindi: 'माइक दबाएं और बोलें',
      AppLanguage.marathi: 'माइक दाबा आणि बोला',
      AppLanguage.tamil: 'மைக் அழுத்தி பேசுங்கள்',
      AppLanguage.gujarati: 'માઇક દબાવી બોલો',
    },
    'listening': {
      AppLanguage.english: 'Listening...',
      AppLanguage.hindi: 'सुन रहा है...',
      AppLanguage.marathi: 'ऐकत आहे...',
      AppLanguage.tamil: 'கேட்கிறது...',
      AppLanguage.gujarati: 'સાંભળે છે...',
    },
    'typeMessage': {
      AppLanguage.english: 'Type a message',
      AppLanguage.hindi: 'संदेश टाइप करें',
      AppLanguage.marathi: 'संदेश टाइप करा',
      AppLanguage.tamil: 'செய்தியை எழுதவும்',
      AppLanguage.gujarati: 'મેસેજ લખો',
    },
    'send': {
      AppLanguage.english: 'Send',
      AppLanguage.hindi: 'भेजें',
      AppLanguage.marathi: 'पाठवा',
      AppLanguage.tamil: 'அனுப்பு',
      AppLanguage.gujarati: 'મોકલો',
    },
    'speechUnavailable': {
      AppLanguage.english: 'Speech input unavailable. Use text input.',
      AppLanguage.hindi: 'वॉइस इनपुट उपलब्ध नहीं है। टेक्स्ट का उपयोग करें।',
      AppLanguage.marathi: 'व्हॉइस इनपुट उपलब्ध नाही. टेक्स्ट वापरा.',
      AppLanguage.tamil: 'குரல் உள்ளீடு இல்லை. எழுத்தை பயன்படுத்தவும்.',
      AppLanguage.gujarati: 'વોઇસ ઇનપુટ ઉપલબ્ધ નથી. ટેક્સ્ટ વાપરો.',
    },
    'ttsUnavailable': {
      AppLanguage.english: 'Speech output unavailable on this platform.',
      AppLanguage.hindi: 'इस प्लेटफॉर्म पर वॉइस आउटपुट उपलब्ध नहीं है।',
      AppLanguage.marathi: 'या प्लॅटफॉर्मवर व्हॉइस आउटपुट उपलब्ध नाही.',
      AppLanguage.tamil: 'இந்த பிளாட்ஃபாரத்தில் குரல் வெளியீடு இல்லை.',
      AppLanguage.gujarati: 'આ પ્લેટફોર્મ પર વોઇસ આઉટપુટ ઉપલબ્ધ નથી.',
    },
    'historyEmpty': {
      AppLanguage.english: 'No conversations yet.',
      AppLanguage.hindi: 'अब तक कोई बातचीत नहीं।',
      AppLanguage.marathi: 'अजून कोणतेही संभाषण नाही.',
      AppLanguage.tamil: 'இதுவரை உரையாடல் இல்லை.',
      AppLanguage.gujarati: 'હજુ કોઈ વાતચીત નથી.',
    },
    'clearHistory': {
      AppLanguage.english: 'Clear history',
      AppLanguage.hindi: 'इतिहास साफ़ करें',
      AppLanguage.marathi: 'इतिहास साफ करा',
      AppLanguage.tamil: 'வரலாற்றை அழி',
      AppLanguage.gujarati: 'ઇતિહાસ સાફ કરો',
    },
    'sttPermissionDenied': {
      AppLanguage.english: 'Microphone permission denied.',
      AppLanguage.hindi: 'माइक्रोफोन अनुमति अस्वीकृत।',
      AppLanguage.marathi: 'मायक्रोफोन परवानगी नाकारली.',
      AppLanguage.tamil: 'மைக்ரோஃபோன் அனுமதி மறுக்கப்பட்டது.',
      AppLanguage.gujarati: 'માઇક્રોફોન પરવાનગી નકારી.',
    },
    'retrying': {
      AppLanguage.english: 'Retrying with stricter constraints...',
      AppLanguage.hindi: 'सख्त नियमों के साथ फिर कोशिश...',
      AppLanguage.marathi: 'कडक अटींसह पुन्हा प्रयत्न...',
      AppLanguage.tamil: 'கட்டுப்பாடுகளுடன் மீண்டும் முயற்சி...',
      AppLanguage.gujarati: 'કડક નિયમો સાથે ફરી પ્રયત્ન...',
    },
  };

  String _value(String key) =>
      _strings[key]?[language] ?? _strings[key]?[AppLanguage.english] ?? key;

  String get appTitle => _value('appTitle');
  String get selectLanguage => _value('selectLanguage');
  String get tapToSpeak => _value('tapToSpeak');
  String get listening => _value('listening');
  String get typeMessage => _value('typeMessage');
  String get send => _value('send');
  String get speechUnavailable => _value('speechUnavailable');
  String get ttsUnavailable => _value('ttsUnavailable');
  String get historyEmpty => _value('historyEmpty');
  String get clearHistory => _value('clearHistory');
  String get sttPermissionDenied => _value('sttPermissionDenied');
  String get retrying => _value('retrying');
}

/// Response templates and prefixes by language.
class ResponseStrings {
  const ResponseStrings(this.language);

  final AppLanguage language;

  static const Map<String, Map<AppLanguage, String>> _strings = {
    'summaryPrefix': {
      AppLanguage.english: 'Summary:',
      AppLanguage.hindi: 'सारांश:',
      AppLanguage.marathi: 'सारांश:',
      AppLanguage.tamil: 'சுருக்கம்:',
      AppLanguage.gujarati: 'સારાંશ:',
    },
    'translationPrefix': {
      AppLanguage.english: 'Translation:',
      AppLanguage.hindi: 'अनुवाद:',
      AppLanguage.marathi: 'भाषांतर:',
      AppLanguage.tamil: 'மொழிபெயர்ப்பு:',
      AppLanguage.gujarati: 'અનુવાદ:',
    },
    'stepsPrefix': {
      AppLanguage.english: 'Steps:',
      AppLanguage.hindi: 'कदम:',
      AppLanguage.marathi: 'पायऱ्या:',
      AppLanguage.tamil: 'படிகள்:',
      AppLanguage.gujarati: 'પગલાં:',
    },
    'shortAnswer': {
      AppLanguage.english: 'Short answer:',
      AppLanguage.hindi: 'संक्षिप्त उत्तर:',
      AppLanguage.marathi: 'संक्षिप्त उत्तर:',
      AppLanguage.tamil: 'சுருக்கமான பதில்:',
      AppLanguage.gujarati: 'ટૂંકું જવાબ:',
    },
    'chatGreeting': {
      AppLanguage.english: 'Hello! How can I help?',
      AppLanguage.hindi: 'नमस्ते! मैं कैसे मदद करूं?',
      AppLanguage.marathi: 'नमस्कार! मी कशी मदत करू?',
      AppLanguage.tamil: 'வணக்கம்! எப்படி உதவலாம்?',
      AppLanguage.gujarati: 'નમસ્તે! હું કેવી રીતે મદદ કરું?',
    },
    'translationFallback': {
      AppLanguage.english: 'I can translate short common phrases. Please simplify.',
      AppLanguage.hindi: 'मैं छोटे सामान्य वाक्यों का अनुवाद कर सकता हूं। कृपया सरल करें।',
      AppLanguage.marathi: 'मी छोटे सामान्य वाक्यांचे भाषांतर करू शकतो. कृपया साधे करा.',
      AppLanguage.tamil: 'சிறிய பொதுவான வாக்கியங்களை மொழிபெயர்க்க முடியும். தயவுசெய்து எளிமையாக்கவும்.',
      AppLanguage.gujarati: 'હું નાના સામાન્ય વાક્યોનો અનુવાદ કરી શકું છું. કૃપા કરીને સરળ કરો.',
    },
    'qnaFallback': {
      AppLanguage.english: 'I can answer short app-related questions. Please rephrase.',
      AppLanguage.hindi: 'मैं ऐप से जुड़े छोटे सवालों का जवाब दे सकता हूं। कृपया दोबारा पूछें।',
      AppLanguage.marathi: 'मी अॅपशी संबंधित छोटे प्रश्नांची उत्तरे देऊ शकतो. कृपया पुन्हा विचारा.',
      AppLanguage.tamil: 'ஆப்புக்குச் சம்பந்தமான சுருக்கமான கேள்விகளுக்கு பதிலளிக்க முடியும். தயவுசெய்து மறுபடியும் கேளுங்கள்.',
      AppLanguage.gujarati: 'હું એપ સંબંધિત નાના પ્રશ્નોના જવાબ આપી શકું છું. કૃપા કરીને ફરી પૂછો.',
    },
    'taskFallback': {
      AppLanguage.english: 'I can outline simple steps. Tell me the goal in one line.',
      AppLanguage.hindi: 'मैं सरल कदम बता सकता हूं। कृपया एक लाइन में लक्ष्य बताएं।',
      AppLanguage.marathi: 'मी सोपे टप्पे सांगू शकतो. कृपया एक ओळीत उद्दिष्ट सांगा.',
      AppLanguage.tamil: 'எளிய படிகளை கூற முடியும். நோக்கத்தை ஒரு வரியில் சொல்லுங்கள்.',
      AppLanguage.gujarati: 'હું સરળ પગલાં આપી શકું છું. કૃપા કરીને એક લાઈનમાં હેતુ કહો.',
    },
    'summaryFallback': {
      AppLanguage.english: 'Please provide a longer text to summarize.',
      AppLanguage.hindi: 'कृपया सारांश के लिए लंबा टेक्स्ट दें।',
      AppLanguage.marathi: 'कृपया सारांशासाठी मोठा मजकूर द्या.',
      AppLanguage.tamil: 'சுருக்கம் செய்ய நீளமான உரையை வழங்கவும்.',
      AppLanguage.gujarati: 'સારાંશ માટે લાંબો ટેક્સ્ટ આપો.',
    },
  };

  String _value(String key) =>
      _strings[key]?[language] ?? _strings[key]?[AppLanguage.english] ?? key;

  String get summaryPrefix => _value('summaryPrefix');
  String get translationPrefix => _value('translationPrefix');
  String get stepsPrefix => _value('stepsPrefix');
  String get shortAnswer => _value('shortAnswer');
  String get chatGreeting => _value('chatGreeting');
  String get translationFallback => _value('translationFallback');
  String get qnaFallback => _value('qnaFallback');
  String get taskFallback => _value('taskFallback');
  String get summaryFallback => _value('summaryFallback');
}
