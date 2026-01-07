# vani_edge

Local-first, voice-enabled AI assistant built with Flutter and llama.cpp.

## Setup

1) Download the model (kept out of git):
```
scripts/download_model.sh
```

2) Build the desktop llama-cli binary (Linux/macOS/Windows):
```
scripts/build_llama_cli.sh /path/to/llama.cpp
```

3) Build Android native libs:
```
scripts/build_android_llama.sh /path/to/llama.cpp arm64-v8a 24
```

## Run

Desktop:
```
flutter run -d linux
```

Android (local LLM enabled):
```
flutter run -d <device> --release --dart-define=ENABLE_LOCAL_LLM=true
```
