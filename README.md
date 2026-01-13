# Vani Edge

Speech-enabled, multi-lingual, local-first assistant built with Flutter (Option B: small on-device model + prompt wrapper). The same Dart logic runs across Android, Web, and Linux to keep response quality consistent.

## Features
- Speech-to-text and text-to-speech with live mic input (best effort by platform)
- 5-language UX: English, Hindi, Marathi, Tamil, Gujarati
- Local intent model (naive Bayes) + prompt wrapper (constraints, retry, cache)
- Local knowledge base for consistent answers
- Conversation history persisted locally

## Quick Start
```bash
flutter pub get
flutter run
```

### Build Outputs
```bash
flutter build apk
flutter build web
```
Outputs:
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`
- Web: `build/web`

## Architecture & Docs
See the `/docs` folder:
- `docs/architecture.md`
- `docs/prompt_wrapper.md`
- `docs/performance.md`
- `docs/limitations.md`
- `docs/timesheet.md`
- `docs/execution_plan.md`

## File Map (Key Paths + Purpose)
```
lib/main.dart                            # App entry point and wiring
lib/core/app_language.dart               # Language config + UI/response strings
lib/core/app_localizations.dart          # Localization delegate
lib/core/app_settings.dart               # App settings (selected language)
lib/features/speech/speech_service.dart  # STT wrapper (speech_to_text)
lib/features/speech/tts_service.dart     # TTS wrapper (flutter_tts)
lib/features/chat/presentation/chat_screen.dart      # UI widgets
lib/features/chat/presentation/chat_controller.dart  # Orchestration
lib/features/chat/domain/intent_model.dart           # Naive Bayes intent model
lib/features/chat/domain/prompt_wrapper.dart         # Constraints + retry + cache
lib/features/chat/domain/local_model.dart            # Templates + chat heuristics
lib/features/chat/domain/message.dart                # History DTO
lib/features/chat/data/knowledge_base.dart           # KB lookup logic
lib/features/chat/data/response_cache.dart           # Response cache
lib/features/chat/data/conversation_store.dart       # History persistence
assets/intent_samples.json               # Intent training samples
assets/knowledge_base.json               # Local KB answers/keywords
docs/architecture.md                     # System design + module map
docs/prompt_wrapper.md                   # Wrapper spec
docs/performance.md                      # Measurements
docs/limitations.md                      # Known limits
```

## Project Tree (Key Structure)
```
.
├── assets/
│   ├── intent_samples.json
│   └── knowledge_base.json
├── docs/
│   ├── architecture.md
│   ├── execution_plan.md
│   ├── limitations.md
│   ├── performance.md
│   ├── prompt_wrapper.md
│   └── timesheet.md
├── lib/
│   ├── core/
│   │   ├── app_language.dart
│   │   ├── app_localizations.dart
│   │   └── app_settings.dart
│   ├── features/
│   │   ├── chat/
│   │   │   ├── data/
│   │   │   │   ├── conversation_store.dart
│   │   │   │   ├── knowledge_base.dart
│   │   │   │   └── response_cache.dart
│   │   │   ├── domain/
│   │   │   │   ├── intent.dart
│   │   │   │   ├── intent_model.dart
│   │   │   │   ├── local_model.dart
│   │   │   │   ├── message.dart
│   │   │   │   └── prompt_wrapper.dart
│   │   │   └── presentation/
│   │   │       ├── chat_controller.dart
│   │   │       └── chat_screen.dart
│   │   └── speech/
│   │       ├── speech_service.dart
│   │       └── tts_service.dart
│   └── main.dart
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Local Model (Option B)
- Intent detection: lightweight naive Bayes model trained from `assets/intent_samples.json`
- Response generation: structured templates + local knowledge base `assets/knowledge_base.json`
- Prompt wrapper: enforces language + format, retries once on low-quality output, and caches responses

## Speech Notes
- Android uses platform speech services; microphone permission required
- Web uses browser SpeechRecognition/SpeechSynthesis (Chrome recommended)
- Linux support is best-effort; STT/TTS may be unavailable and will fall back to text-only

## Demo Checklist
- Language switching
- Mic STT
- Response + TTS
- Offline/local inference path
- Repo structure + key modules
