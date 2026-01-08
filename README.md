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

## Architecture & Docs
See the `/docs` folder:
- `docs/architecture.md`
- `docs/prompt_wrapper.md`
- `docs/performance.md`
- `docs/limitations.md`
- `docs/timesheet.md`
- `docs/execution_plan.md`

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

## Timesheet
Add your Google Sheet link in `docs/timesheet.md`.

## Transcript / Recording
Add transcript or recording link in `docs/limitations.md`.
