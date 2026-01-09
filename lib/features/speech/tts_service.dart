import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _available = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    // Attempt to configure TTS; disable if plugin unavailable (Linux/web variance).
    try {
      if (kIsWeb) {
        await _tts.setVolume(1.0);
      }
      await _tts.setSpeechRate(kIsWeb ? 0.7 : 0.5);
      _available = true;
    } on MissingPluginException {
      _available = false;
    } catch (_) {
      _available = false;
    }
    _initialized = true;
  }

  Future<bool> speak({required String text, required String localeId}) async {
    if (!_available) {
      return false;
    }
    try {
      await _tts.setLanguage(localeId);
      final result = await _tts.speak(text);
      return result == 1 || result == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    if (_available) {
      await _tts.stop();
    }
  }
}
