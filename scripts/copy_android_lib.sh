#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /home/dinesh/Documents/llama.cpp/build/bin/libllama.so"
  echo "Example: $0 ~/llama.cpp/build-android/arm64-v8a/libllama.so arm64-v8a"
  exit 1
fi

SOURCE_LIB="$1"
ABI="${2:-arm64-v8a}"

if [[ ! -f "$SOURCE_LIB" ]]; then
  echo "Error: source library not found: $SOURCE_LIB"
  exit 1
fi

TARGET_DIR="android/app/src/main/jniLibs/$ABI"
TARGET_LIB="$TARGET_DIR/libllama.so"

mkdir -p "$TARGET_DIR"
cp -f "$SOURCE_LIB" "$TARGET_LIB"

echo "Copied $SOURCE_LIB -> $TARGET_LIB"
