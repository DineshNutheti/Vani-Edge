import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_language.dart';
import 'core/app_localizations.dart';
import 'core/app_settings.dart';
import 'features/chat/data/conversation_store.dart';
import 'features/chat/data/knowledge_base.dart';
import 'features/chat/data/response_cache.dart';
import 'features/chat/domain/intent_model.dart';
import 'features/chat/presentation/chat_controller.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/speech/speech_service.dart';
import 'features/speech/tts_service.dart';

void main() {
  runApp(const VaniEdgeApp());
}

/// Root widget that wires app settings and the chat controller.
class VaniEdgeApp extends StatefulWidget {
  const VaniEdgeApp({super.key});

  @override
  State<VaniEdgeApp> createState() => _VaniEdgeAppState();
}

class _VaniEdgeAppState extends State<VaniEdgeApp> {
  late final AppSettings _settings;
  late final ChatController _chatController;

  @override
  void initState() {
    super.initState();
    // Use system locale when available so the first render matches device language.
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    _settings = AppSettings(language: AppLanguages.fromLocale(systemLocale));
    _chatController = ChatController(
      settings: _settings,
      speechService: SpeechService(),
      ttsService: TtsService(),
      conversationStore: ConversationStore(),
      responseCache: ResponseCache(),
      intentModel: IntentModel(),
      knowledgeBase: KnowledgeBase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        final language = _settings.language;
        return MaterialApp(
          title: 'Vani Edge',
          locale: AppLanguages.config(language).locale,
          supportedLocales: [
            for (final lang in AppLanguages.all) AppLanguages.config(lang).locale,
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C7B)),
            useMaterial3: true,
          ),
          home: ChatScreen(
            controller: _chatController,
          ),
        );
      },
    );
  }
}
