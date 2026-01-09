import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> init({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    // Initialize speech engine; gracefully handle missing plugins.
    try {
      _isAvailable = await _speech.initialize(
        onStatus: onStatus,
        onError: (error) {
          if (onError != null) {
            onError(error.errorMsg);
          }
        },
      );
    } catch (_) {
      _isAvailable = false;
      if (onError != null) {
        onError('Speech plugin unavailable');
      }
    }
    return _isAvailable;
  }

  Future<void> startListening({
    required String localeId,
    required void Function(String text) onResult,
  }) async {
    await _speech.listen(
      localeId: localeId,
      onResult: (result) => onResult(result.recognizedWords),
      listenMode: ListenMode.confirmation,
      partialResults: true,
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
