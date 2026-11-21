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

bundle_dir="build/web"
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    --output=*) bundle_dir="${args[$i]#--output=}" ;;
    --output)
      if ((i + 1 < ${#args[@]})); then
        bundle_dir="${args[$((i + 1))]}"
      fi
      ;;
  esac
done

flutter build web --release --pwa-strategy=offline-first "$@"
bash scripts/verify_web_bundle.sh "$bundle_dir"
