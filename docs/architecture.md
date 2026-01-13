# Architecture

## 8.1 System Diagram (Simple)
```
[UI (Flutter)]
     |
     v
[Speech Layer (STT/TTS)]
     |
     v
[Prompt Wrapper]
     |
     v
[Local Model Runtime]
     |
     v
[Storage: History + Cache]

(Optional)
[Translation Layer] -> handled by response templates per language
```

## 8.2 Module Boundaries (with Paths)
- `lib/main.dart`: app bootstrap, theme, localization delegates, wiring of services and controller.
- `lib/core/app_language.dart`: language list, locale/stt/tts mappings, UI strings, response strings.
- `lib/core/app_localizations.dart`: localization delegate and lookup wrapper.
- `lib/core/app_settings.dart`: app state for selected language.
- `lib/features/speech/speech_service.dart`: STT init/listen/stop using `speech_to_text` plugin.
- `lib/features/speech/tts_service.dart`: TTS init/speak/stop using `flutter_tts` with graceful fallback.
- `lib/features/chat/domain/intent.dart`: intent enums and result model.
- `lib/features/chat/domain/intent_model.dart`: Naive Bayes intent classifier trained from assets.
- `lib/features/chat/domain/local_model.dart`: response templates + knowledge base + chat heuristics.
- `lib/features/chat/domain/prompt_wrapper.dart`: constraints, caching, retry, validation.
- `lib/features/chat/domain/message.dart`: message DTO for history persistence.
- `lib/features/chat/data/knowledge_base.dart`: keyword match lookup from `assets/knowledge_base.json`.
- `lib/features/chat/data/response_cache.dart`: response cache in shared preferences.
- `lib/features/chat/data/conversation_store.dart`: history store in shared preferences.
- `lib/features/chat/presentation/chat_controller.dart`: orchestration of STT, wrapper, model, TTS, history.
- `lib/features/chat/presentation/chat_screen.dart`: UI, message list, input bar, status banner.

## 8.2.1 Project Layout (Top-Level)
```
.
├── assets/          # intent samples + knowledge base
├── docs/            # architecture, wrapper spec, performance, limitations
├── lib/             # Dart source (core + features)
├── android/         # Android host project
├── ios/             # iOS host project
├── linux/           # Linux desktop host project
├── macos/           # macOS host project
├── web/             # Web host project
├── windows/         # Windows host project
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## 8.3 Data Flow
Mic input -> STT -> prompt wrapper -> local model -> wrapper -> UI -> TTS

## 8.4 Key Design Decisions
- Model/runtime: Option B small local model for deterministic, fast, cross-platform behavior.
- STT/TTS: platform services (speech_to_text + flutter_tts) for best reach under time constraints.
- Multi-language: centralized language config + localized UI strings + response templates per language.
- Not done: full LLM chat due to size/time; roadmap includes llama.cpp on-device.

## 8.5 Risk & Mitigation
- Model too simplistic -> wrapper enforces format + retries + cached best responses.
- STT language quality varies -> allow manual text input and document limitations.
- Web limitations -> use browser speech APIs; if unsupported, fall back to text-only.

## 8.6 Data Models
- `Message`: `{id, text, isUser, timestamp, language}` stored as JSON in history.
- `Intent`: translate, summarize, qna, task, chat.
- `IntentResult`: `{intent, confidence, scores}` from Naive Bayes classifier.
- `ModelRequest`: `{intent, language, userText, maxWords, strict}`.
- `ModelResponse`: `{intent, text}`.

## 8.7 Assets and Local Data
- `assets/intent_samples.json`: training samples for Naive Bayes intent model.
- `assets/knowledge_base.json`: keyword-indexed QnA entries per language.
- `shared_preferences` keys:
  - `conversation_history`: list of `Message` JSON.
  - `response_cache`: map of cache key to response text.

## 8.8 Intent Model (Naive Bayes)
- Implementation: `lib/features/chat/domain/intent_model.dart`.
- Tokenization: lowercase, remove punctuation/symbols, split on whitespace.
- Training: counts words per intent from `intent_samples.json`.
- Inference: compute log probabilities with Laplace smoothing, pick max intent.
- Output: normalized scores and confidence used by prompt wrapper.

## 8.9 Prompt Wrapper
- Implementation: `lib/features/chat/domain/prompt_wrapper.dart`.
- Cache key: `langCode::intent::normalizedText`.
- Validation: non-empty, word limit, script match (Devanagari/Tamil/Gujarati).
- Retry: one strict retry when validation fails.
- Max words by intent: translate 30, summarize 40, qna 35, task 45, chat 20.

## 8.10 Local Model Logic
- `translate`: glossary-based translations for common phrases; fallback template when missing.
- `summarize`: first two sentences if >= 8 words; limited to max words.
- `qna`: keyword match in knowledge base (token overlap score), else fallback response.
- `task`: localized 3-step templates with user goal summary.
- `chat`: greeting/thanks/follow-up variants + simple name extraction.
- Name extraction: regex per language (e.g., "my name is", "mera naam"); validates alphabetic tokens.
- Response variety: deterministic selection via input hash to avoid random behavior.

## 8.11 Speech Layer Details
- STT: `SpeechToText.initialize` with status/error callbacks.
- Listen mode: `ListenMode.confirmation`, partial results enabled.
- TTS: `flutter_tts` with speech rate 0.5 (mobile), 0.7 (web); handles missing plugin.

## 8.12 UI Behavior
- Language dropdown controls locale + STT/TTS locale IDs.
- Status banner shows listening, STT error, TTS unavailable, or retrying.
- History persists across app restarts; clear via app bar trash icon.

## 8.13 Tests
- `test/prompt_wrapper_test.dart`: intent detection, caching, language validation.
- `test/widget_test.dart`: app loads and title renders.

## 8.14 Build Outputs
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`.
- Web build: `build/web` (JS build; WASM warnings due to flutter_tts web interop).

## 8.15 Platform Configuration
- Android: `RECORD_AUDIO` + `INTERNET` permissions in `android/app/src/main/AndroidManifest.xml`.
- iOS: `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` in `ios/Runner/Info.plist`.
- Web: app name/description in `web/manifest.json` and `web/index.html`.

## 8.16 Language Configuration
- Supported languages: English (en), Hindi (hi), Marathi (mr), Tamil (ta), Gujarati (gu).
- STT locale IDs: `en_IN`, `hi_IN`, `mr_IN`, `ta_IN`, `gu_IN`.
- TTS locale IDs: `en-IN`, `hi-IN`, `mr-IN`, `ta-IN`, `gu-IN`.
