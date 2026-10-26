# MSS OFFLINE AI — Full Flutter Android Application

**Mukhlis Software Solutions | Version 1.1.1 | Android (ARM64)**

MSS AI opens directly into a ChatGPT-style mobile chat. Ask questions, translate, write, rewrite, and summarize in the same conversation. The Flutter app uses local GGUF inference through `llama_flutter_android`; a compatible model must be installed and loaded before sending messages.

Type the language instruction directly into your message; no language selection is required:

- `Translate to Pashto: Hello, how are you?`
- `Translate this into English: سلام`
- `Write a professional email in Dari about tomorrow’s meeting.`
- `Summarize this in German: ...`

Completed messages are saved automatically on this device in separate conversations. Open the menu to search and reopen chats, rename or delete a chat, or start a new chat without losing earlier conversations. Existing single-chat history migrates automatically. Chats are local and do not sync between devices. The model sees only recent messages to fit the phone’s memory; the full saved log remains available in history.

## IMPORTANT: first-run setup (DO NOT run `flutter create` alone)

The previous ZIP accidentally resulted in a Flutter starter page on your phone after the scaffold step. In this version, run the protected setup script: **it backs up every application source file and restores it after Flutter generates native Android build files.**

```bash
cd ~/Desktop/MSS_Offline_AI_Translator_COMPLETE
chmod +x scripts/*.sh
bash scripts/bootstrap_android.sh
flutter devices
flutter run -d 108321545U005415
```

If you have a different device ID, replace it. Your previous device was TECNO BG7. The app will open the MSS AI chat screen. If any checks fail, fix the printed errors before running.

The script runs `flutter create` **safely**, `flutter pub get`, `flutter analyze` and `flutter test`. Do not use `flutter create --overwrite` yourself; it can regenerate the default main.dart and branding. You can also run `bash scripts/bootstrap_android.sh` again to repair generated files.

### If you see the old counter app anyway

1. Ensure the new folder contains `lib/screens/chat_screen.dart` and `assets/images/mss_ai_logo.png`.
2. Run `grep 'MssApp(engine:' lib/main.dart` to confirm the real entry point exists.
3. Run `flutter clean`, `flutter pub get`, then `flutter run -d 108321545U005415`.
4. Uninstall `com.example.mss_offline_ai` if you are still launching an OLD installation (this new package is `com.mss.offline_ai`).

## Get real offline AI working

The ~563 MB Qwen3.5-0.8B Q4_0 model weights **could not be included** in the source ZIP because this environment cannot retrieve the remote binary. This is disclosed, not substituted with fake AI. All UI, model download code, and native inference calls are real source code.

**Option A (inside app):** Menu > Settings > Download model > verify downloaded SHA-256 > Start AI. First download needs internet; translations, writing and chat afterward use local inference without an API.

**Option B (Ubuntu then USB):**

```bash
bash scripts/download_verified_model.sh
adb push model_download/Qwen3.5-0.8B-Q4_0.gguf /sdcard/Download/
```

Then in the app open Settings > Import from device > select the model file > Start AI. The imported model is copied into private application storage.

Official verified source: https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/blob/main/Qwen3.5-0.8B-Q4_0.gguf
SHA-256 `57d1997790d1744fba5b40a7317df71ea5e2acee28c47e78f0cce39c0703f8cf`
Model uses Apache 2.0 (follow upstream attribution/license).

## Main screens

- **Chat:** prompt-based translation, writing and questions, streamed replies, copy and stop controls, and automatic conversation saving.
- **History drawer:** search chats by title or message, reopen, rename, delete, or start a new conversation.
- **Settings:** appearance, offline AI download/import and startup, with memory and removal controls under Advanced.

## Hardware and accuracy warnings

**2 GB RAM is a target, not a tested or guaranteed supported minimum.** Start with low-memory mode, 512-token context, short generation and 2 CPU threads. A 563 MB disk file is not the same as peak RAM usage; Android may close the app under memory pressure. The selected native plugin's prebuilt llama.cpp must support the Qwen3.5 GGUF architecture; that combination has NOT been device-validated here. If model loading fails due to architecture support, the native llama.cpp backend will need an update. We cannot truthfully claim verified inference on your specific phone without running the device.

**0.8B AI will not achieve cloud ChatGPT-level accuracy**, particularly for Pashto and Dari. Evaluate each of the 12 directions with native speakers before release.

## Verification actually performed vs. still required

- Verified: full source tree, app entry point, custom Flutter UI/screens, branding assets, manifest, Android Gradle source, native inference service references, checksum/model URL, executable setup/download scripts, ZIP integrity.
- Not verified here: `flutter analyze`, `flutter test`, Gradle compilation, native model load, on-device performance, translations, 2 GB peak RAM. No Flutter/Android SDK is installed in the artifact creation environment.

Your previous device logs show Flutter built and launched an app but displayed the starter screen. These are not AI model loading logs. Use the protected script above to preserve the actual MSS app code.

## Dependencies and licenses

- Flutter 3.47.x / Dart 3.13.x compatible source syntax.
- `llama_flutter_android: ^0.2.6` (MIT, native llama.cpp); `dio`, `file_picker`, `shared_preferences`, `share_plus`, `path_provider`, `crypto`.
- Internet permission is for first-time model download only; the model inference stream is local. Model is NOT automatically bundled in an APK.
- Saved text history is stored using SharedPreferences (not encrypted); don't save secrets/financial credentials until encrypted storage is implemented.
- For Google Play release, configure a production signing key and perform performance/security QA.

## Build APK locally after successful tests

```bash
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

Please do **not** represent this as production-verified software until the real GGUF successfully loads and completes offline inference on an Android phone.

## 1.1.1 analyzer cleanup

This release addresses the analyzer diagnostics reported with Flutter 3.47.5: two unused imports, the deprecated `Color.withOpacity` and `DropdownButtonFormField.value` APIs, missing braces in the writing save action, and redundant string interpolation. The writing action also now correctly names the rewrite task.

Static checks were performed on the source archive, but `flutter analyze`/`flutter test` still need to be run on the developer's Ubuntu machine. These changes do not claim to verify native GGUF inference or performance on 2 GB phones.
