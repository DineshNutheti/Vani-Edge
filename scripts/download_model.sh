#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL_NAME="${1:-tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
MODEL_URL_DEFAULT="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/${MODEL_NAME}"
MODEL_URL="${MODEL_URL:-$MODEL_URL_DEFAULT}"
OUT_DIR="${MODEL_DIR:-$ROOT_DIR/assets/models}"
OUT_PATH="$OUT_DIR/$MODEL_NAME"

mkdir -p "$OUT_DIR"

if [[ -f "$OUT_PATH" ]]; then
  echo "Model already exists: $OUT_PATH"
  exit 0
fi

echo "Downloading model: $MODEL_NAME"
if command -v curl >/dev/null 2>&1; then
  curl -L --fail --retry 3 --retry-delay 2 -o "$OUT_PATH" "$MODEL_URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$OUT_PATH" "$MODEL_URL"
else
  echo "Error: curl or wget is required to download the model."
  exit 1
fi

echo "Download complete: $OUT_PATH"
