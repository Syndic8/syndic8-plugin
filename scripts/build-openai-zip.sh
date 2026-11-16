#!/usr/bin/env bash
# Packages syndic8/ as the ZIP the OpenAI plugin dashboard takes (plugin root at the archive root).
# OpenAI has no upload API, so CI builds this and a person uploads it at platform.openai.com/plugins.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(python3 -c 'import json; print(json.load(open("syndic8/.codex-plugin/plugin.json"))["version"])')
out="dist/syndic8-openai-${version}.zip"
mkdir -p dist
rm -f "$out"
(cd syndic8 && zip -qrX "../$out" . -x 'evals/*' -x '*.DS_Store')
echo "$out"
