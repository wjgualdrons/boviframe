#!/usr/bin/env bash
# scripts/build_android.sh
# Usage: ./scripts/build_android.sh
# Builds Android release APK and AAB. Requires flutter in PATH.

set -euo pipefail

echo "Checking flutter in PATH..."
if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found in PATH. Install Flutter and add to PATH." >&2
  exit 1
fi

echo "Running flutter pub get"
flutter pub get

echo "Building release APK..."
flutter build apk --release
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
  echo "APK created: $APK_PATH"
else
  echo "APK not found at expected path: $APK_PATH" >&2
fi

echo "Building App Bundle (AAB)..."
flutter build appbundle --release
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
  echo "AAB created: $AAB_PATH"
else
  echo "AAB not found at expected path: $AAB_PATH" >&2
fi

echo "Done. You can install the APK with: adb install -r $APK_PATH"