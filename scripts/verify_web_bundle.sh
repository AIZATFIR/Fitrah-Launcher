#!/usr/bin/env bash
set -euo pipefail

bundle=${1:-build/web}
required=(
  index.html
  flutter.js
  flutter_bootstrap.js
  flutter_service_worker.js
  main.dart.js
  manifest.json
  favicon.png
  icons/Icon-192.png
  assets/AssetManifest.bin
  assets/FontManifest.json
  assets/fonts/MaterialIcons-Regular.otf
  assets/assets/fitrah_campfire_bg.jpg
  drift_worker.js
  sqlite3.wasm
  version.json
)

for path in "${required[@]}"; do
  if [[ ! -s "$bundle/$path" ]]; then
    printf 'Missing required web release asset: %s\n' "$bundle/$path" >&2
    exit 1
  fi
done

printf 'Web bundle verified: %s\n' "$bundle"
