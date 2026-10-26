#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'ERROR: Install Flutter SDK first.'; exit 1; }
backup=$(mktemp -d)
cleanup() { rm -rf "$backup"; }
trap cleanup EXIT
# Protect our real source, AI service, branding and tests from Flutter's scaffold generator.
for item in lib assets test pubspec.yaml analysis_options.yaml; do
  if [[ -e "$item" ]]; then cp -a "$item" "$backup/"; fi
done
mkdir -p "$backup/android/app"
if [[ -d android/app/src/main ]]; then cp -a android/app/src/main "$backup/android/app/src_main"; fi
if [[ -f android/app/build.gradle.kts ]]; then cp android/app/build.gradle.kts "$backup/android/app/"; fi
if [[ -f android/settings.gradle.kts ]]; then cp android/settings.gradle.kts "$backup/android/"; fi
if [[ -f android/build.gradle.kts ]]; then cp android/build.gradle.kts "$backup/android/"; fi
if [[ -f android/gradle.properties ]]; then cp android/gradle.properties "$backup/android/"; fi
echo '==> Generating native Flutter files (without losing MSS application code)...'
flutter create --project-name mss_offline_ai --platforms android .
for item in lib assets test pubspec.yaml analysis_options.yaml; do
  if [[ -e "$backup/$item" ]]; then rm -rf "$item"; cp -a "$backup/$item" .; fi
done
if [[ -d "$backup/android/app/src_main" ]]; then
  mkdir -p android/app/src
  rm -rf android/app/src/main
  cp -a "$backup/android/app/src_main" android/app/src/main
fi
for item in android/app/build.gradle.kts android/settings.gradle.kts android/build.gradle.kts android/gradle.properties; do
 if [[ -f "$backup/$item" ]]; then cp -a "$backup/$item" "$item"; fi
done
# Prevent accidental release build with the generated starter main.dart.
grep -q 'MssApp(engine:' lib/main.dart || { echo 'ERROR: Real MSS application entry point missing.'; exit 1; }
grep -q 'class ChatScreen' lib/screens/chat_screen.dart || { echo 'ERROR: MSS UI missing.'; exit 1; }
echo '==> Fetching packages...'
flutter pub get
echo '==> Static analysis...'
flutter analyze
echo '==> Unit + UI smoke tests...'
flutter test
echo 'MSS application source is in place. Run: flutter run -d YOUR_DEVICE_ID'
