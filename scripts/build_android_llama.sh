#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/llama.cpp [abi] [android_api]"
  echo "Example: $0 ~/src/llama.cpp arm64-v8a 24"
  exit 1
fi

LLAMA_DIR="$1"
ABI="${2:-arm64-v8a}"
ANDROID_API="${3:-24}"

if [[ ! -d "$LLAMA_DIR" ]]; then
  echo "Error: llama.cpp directory not found: $LLAMA_DIR"
  exit 1
fi

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  echo "Error: ANDROID_NDK_HOME is not set."
  echo "Set it to your Android NDK path, e.g.:"
  echo "  export ANDROID_NDK_HOME=~/Android/Sdk/ndk/26.1.10909125"
  exit 1
fi

TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
if [[ ! -f "$TOOLCHAIN" ]]; then
  echo "Error: Android toolchain not found at: $TOOLCHAIN"
  exit 1
fi

BUILD_DIR="$LLAMA_DIR/build-android/$ABI"
mkdir -p "$BUILD_DIR"

cmake -S "$LLAMA_DIR" -B "$BUILD_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DANDROID_ABI="$ABI" \
  -DANDROID_PLATFORM="android-$ANDROID_API" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DLLAMA_CURL=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DGGML_OPENMP=OFF

cmake --build "$BUILD_DIR" --config Release -j "$(nproc)" --target llama

LIB_PATH="$BUILD_DIR/libllama.so"
if [[ ! -f "$LIB_PATH" ]]; then
  ALT_LIB_PATH="$BUILD_DIR/bin/libllama.so"
  if [[ -f "$ALT_LIB_PATH" ]]; then
    LIB_PATH="$ALT_LIB_PATH"
  else
    echo "Error: libllama.so not found at: $LIB_PATH"
    exit 1
  fi
fi

if command -v file >/dev/null 2>&1; then
  FILE_DESC="$(file "$LIB_PATH")"
  echo "$FILE_DESC"
  if ! echo "$FILE_DESC" | grep -qiE "aarch64|arm64"; then
    echo "Error: libllama.so is not arm64-v8a. Rebuild with the Android NDK toolchain."
    exit 1
  fi
fi

TARGET_DIR="android/app/src/main/jniLibs/$ABI"
mkdir -p "$TARGET_DIR"

# Copy libllama and its shared dependencies from the build output.
rm -f "$TARGET_DIR"/lib*.so

COPIED=0
if compgen -G "$BUILD_DIR/bin/lib*.so" > /dev/null; then
  for so in "$BUILD_DIR"/bin/lib*.so; do
    cp -f "$so" "$TARGET_DIR/$(basename "$so")"
    COPIED=1
  done
elif compgen -G "$BUILD_DIR/lib*.so" > /dev/null; then
  for so in "$BUILD_DIR"/lib*.so; do
    cp -f "$so" "$TARGET_DIR/$(basename "$so")"
    COPIED=1
  done
fi

if [[ "$COPIED" -eq 0 ]]; then
  echo "Error: no shared libraries found in $BUILD_DIR"
  exit 1
fi

echo "Built and copied shared libraries to: $TARGET_DIR"
