#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p web
release=https://github.com/simolus3/drift/releases/download/drift-2.35.3
acquire() {
  local asset="$1" expected="$2" temporary
  temporary=$(mktemp)
  trap 'rm -f "$temporary"' RETURN
  curl --fail --location --retry 3 "$release/$asset" --output "$temporary"
  printf '%s  %s\n' "$expected" "$temporary" | sha256sum --check
  mv "$temporary" "web/$asset"
}
acquire drift_worker.js a54b81412d4c4ab56653bb9e4c02912b0820bb37e2bba00722ddef4d78083d4a
acquire sqlite3.wasm efd308be92a34f3aa15f289a37f213b0230fd80888a1364326ee29579d892d37
