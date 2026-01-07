import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider<TTSService>((ref) => TTSService());

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  TTSService() {
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text, String language) async {
    // Map UI language to Locale ID
    String localeId = "en-IN"; // Default
    switch (language) {
      case "Hindi": localeId = "hi-IN"; break;
      case "Marathi": localeId = "mr-IN"; break;
      case "Tamil": localeId = "ta-IN"; break;
      case "Gujarati": localeId = "gu-IN"; break;
      case "English": localeId = "en-IN"; break;
    }

    try {
      await _flutterTts.setLanguage(localeId);
      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}