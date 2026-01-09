# Known Limitations & Next Steps

## Limitations
- STT quality varies by platform and language; Hindi/English are most reliable.
- Linux STT/TTS support depends on system services; app falls back to text-only.
- Translation is limited to common phrases (Option B requirement: be honest).
- Responses are template-based with a knowledge base; not a full generative LLM.
- Web speech APIs may require HTTPS or specific browsers.
- If a TTS voice is missing for a selected language, the app returns text only.
- Web TTS sounds slower than mobile due to browser speech engine defaults.
- Web build shows WASM dry-run warnings due to `flutter_tts` web interop checks; JS build works.
- On this Ubuntu setup, Linux STT/TTS plugins are unavailable; text-only flow works.

## Next Steps
- Add larger local model for richer answers (llama.cpp + GGUF on-device)
- Expand translation and summarization with local models
- Improve knowledge base with more domain data
- Add background audio handling and streaming responses

## Transcript / Recording
- Add transcript or recording link here.
