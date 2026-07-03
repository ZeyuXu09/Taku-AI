#!/bin/bash
# Fix Android "GeneratedPluginRegistrant 2.dex" build failures caused by
# iCloud Drive creating duplicate files inside build/. Run from project root:
#   bash scripts/clean_build.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/Develop/flutter/bin:${PATH}"

echo "Cleaning Flutter build artifacts..."
flutter clean

if [ -d build ]; then
  echo "Removing iCloud duplicate files in build/..."
  find build -name '* 2.*' -delete 2>/dev/null || true
  find build -name '* 2' -type f -delete 2>/dev/null || true
  rm -rf build
fi

flutter pub get

echo "Done. You can now run: flutter run"
