#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null; then
  if [ ! -d flutter ]; then
    git clone https://github.com/flutter/flutter.git -b 3.41.9 --depth 1 flutter
  fi
  export PATH="$PWD/flutter/bin:$PATH"
fi
bash scripts/prepare_browser_storage.sh
flutter pub get
flutter build web --release "$@"
