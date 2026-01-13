import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/app_language.dart';
import '../../../core/app_settings.dart';
import '../../speech/speech_service.dart';
import '../../speech/tts_service.dart';
import '../data/conversation_store.dart';
import '../data/response_cache.dart';
import '../domain/intent_model.dart';
import '../domain/local_model.dart';
import '../domain/message.dart';
import '../domain/prompt_wrapper.dart';
import '../data/knowledge_base.dart';

/// Coordinates UI, speech, wrapper, model, and persistence layers.
class ChatController extends ChangeNotifier {
  ChatController({
    required AppSettings settings,
    required SpeechService speechService,
    required TtsService ttsService,
    required ConversationStore conversationStore,
    required ResponseCache responseCache,
    required IntentModel intentModel,
    required KnowledgeBase knowledgeBase,
  })  : _settings = settings,
        _speechService = speechService,
        _ttsService = ttsService,
        _conversationStore = conversationStore,
        _responseCache = responseCache,
        _intentModel = intentModel,
        _knowledgeBase = knowledgeBase,
        _messages = [] {
    _promptWrapper = PromptWrapper(
      intentModel: _intentModel,
      localModel: LocalModel(knowledgeBase: _knowledgeBase),
      cache: _responseCache,
    );
  }

  final AppSettings _settings;
  final SpeechService _speechService;
  final TtsService _ttsService;
  final ConversationStore _conversationStore;
  final ResponseCache _responseCache;
  final IntentModel _intentModel;
  final KnowledgeBase _knowledgeBase;
  late final PromptWrapper _promptWrapper;

  // Source-of-truth for chat UI; persisted to shared prefs after each exchange.
  final List<Message> _messages;
  bool _isListening = false;
  bool _isBusy = false;
  bool _sttAvailable = false;
  String _draftText = '';
  String? _statusMessage;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isBusy => _isBusy;
  bool get sttAvailable => _sttAvailable;
  String get draftText => _draftText;
  String? get statusMessage => _statusMessage;
  AppLanguage get language => _settings.language;

  Future<void> init() async {
    // Load model assets, cache, speech engines, and history before UI interaction.
    await Future.wait([
      _intentModel.loadFromAssets('assets/intent_samples.json'),
      _knowledgeBase.loadFromAssets('assets/knowledge_base.json'),
      _responseCache.load(),
      _ttsService.init(),
    ]);

    _sttAvailable = await _speechService.init(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );

    final stored = await _conversationStore.load();
    _messages
      ..clear()
      ..addAll(stored);

    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    _settings.setLanguage(language);
    notifyListeners();
  }

  void updateDraft(String value) {
    _draftText = value;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_sttAvailable || _speechService.isListening) {
      return;
    }
    _statusMessage = null;
    _isListening = true;
    notifyListeners();
    try {
      await _speechService.startListening(
        localeId: AppLanguages.config(language).sttLocaleId,
        onResult: (text) {
          _draftText = text;
          notifyListeners();
        },
      );
    } catch (_) {
      _statusMessage = 'stt_error';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_speechService.isListening) {
      return;
    }
    await _speechService.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> sendCurrentDraft() async {
    await sendMessage(_draftText);
  }

  /// Orchestrates: user message -> wrapper -> model response -> TTS -> persist.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isBusy) {
      return;
    }
    _isBusy = true;
    _statusMessage = null;
    _draftText = '';
    if (_speechService.isListening) {
      await stopListening();
    }
    _addMessage(Message(
      id: _newId(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      language: language,
    ));

    try {
      final wrapped = await _promptWrapper.handle(trimmed, language);
      // Assistant response is already validated/cached by the wrapper.
      _addMessage(Message(
        id: _newId(),
        text: wrapped.response.text,
        isUser: false,
        timestamp: DateTime.now(),
        language: language,
      ));
      if (wrapped.attempts > 1) {
        _statusMessage = 'retrying';
      }

      await _conversationStore.save(_messages);

      final ttsOk = await _ttsService.speak(
        text: wrapped.response.text,
        localeId: AppLanguages.config(language).ttsLocaleId,
      );
      if (!ttsOk) {
        _statusMessage = 'tts_unavailable';
      }
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _messages.clear();
    await _conversationStore.clear();
    await _responseCache.clear();
    notifyListeners();
  }

  void _addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void _handleSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _handleSpeechError(String error) {
    _statusMessage = 'stt_error';
    _isListening = false;
    notifyListeners();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
