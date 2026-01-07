import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sttServiceProvider = Provider<STTService>((ref) => STTService());

class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => print('STT Error: $val'),
        onStatus: (val) => print('STT Status: $val'),
      );
      return _isAvailable;
    } catch (e) {
      print("STT Init Failed (Normal on Linux): $e");
      return false;
    }
  }

  void listen({required Function(String) onResult, String language = "English"}) async {
    if (!_isAvailable) {
      print("STT not initialized or not supported on this device.");
      return;
    }

    _speech.listen(
      onResult: (val) {
        if (val.hasConfidenceRating && val.confidence > 0) {
          onResult(val.recognizedWords);
        }
      },
      localeId: _localeForLanguage(language),
    );
  }

  void stop() {
    _speech.stop();
  }
  
  bool get isListening => _speech.isListening;

  String _localeForLanguage(String language) {
    switch (language) {
      case "Hindi":
        return "hi-IN";
      case "Marathi":
        return "mr-IN";
      case "Tamil":
        return "ta-IN";
      case "Gujarati":
        return "gu-IN";
      case "English":
      default:
        return "en-IN";
    }
  }
}
