#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/llama.cpp [Release|Debug]"
  exit 1
fi

LLAMA_DIR="$(cd "$1" && pwd)"
BUILD_TYPE="${2:-Release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/assets/bin"

JOBS="${JOBS:-}"
if [[ -z "$JOBS" ]]; then
  if command -v nproc >/dev/null 2>&1; then
    JOBS="$(nproc)"
  else
    JOBS="4"
  fi
fi

cmake -S "$LLAMA_DIR" -B "$LLAMA_DIR/build" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cmake --build "$LLAMA_DIR/build" --config "$BUILD_TYPE" --target llama-cli -j "$JOBS"

BIN_CANDIDATES=(
  "$LLAMA_DIR/build/bin/llama-cli"
  "$LLAMA_DIR/build/llama-cli"
  "$LLAMA_DIR/build/bin/main"
  "$LLAMA_DIR/build/main"
)

BIN_PATH=""
for candidate in "${BIN_CANDIDATES[@]}"; do
  if [[ -f "$candidate" ]]; then
    BIN_PATH="$candidate"
    break
  fi
done

if [[ -z "$BIN_PATH" ]]; then
  echo "Error: could not find a built llama-cli binary."
  echo "Looked in: ${BIN_CANDIDATES[*]}"
  exit 1
fi

mkdir -p "$OUT_DIR"
cp -f "$BIN_PATH" "$OUT_DIR/llama-cli"
chmod +x "$OUT_DIR/llama-cli"

echo "Copied $BIN_PATH -> $OUT_DIR/llama-cli"
