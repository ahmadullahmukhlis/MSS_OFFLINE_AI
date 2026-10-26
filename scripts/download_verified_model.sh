#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p "model_download"
cd model_download
url="https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_0.gguf"
model="Qwen3.5-0.8B-Q4_0.gguf"
expected="57d1997790d1744fba5b40a7317df71ea5e2acee28c47e78f0cce39c0703f8cf"
echo 'Downloading the actual ~563 MB quantized Qwen3.5 model from ggml-org/Hugging Face...'
curl -fL --retry 3 -C - -o "$model" "$url"
echo "$expected  $model" | sha256sum -c -
echo 'Model verified. To transfer it to Android Downloads, connect your phone and execute:'
echo "  adb push model_download/$model /sdcard/Download/$model"
echo 'Then open MSS AI > Settings > Import from device.'
