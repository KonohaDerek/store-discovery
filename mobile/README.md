# Mobile

iOS/Android Flutter client workspace.

Flutter 3.47.6 is intended to run in the project DevContainer. SDK setup is
tracked separately; do not install project SDKs on the Mac host. The Mac host
only supplies Xcode for iOS simulator, build, signing, and distribution work.

Set `API_BASE_URL` with `--dart-define` when running the app. For the Android
emulator, use the host alias `http://10.0.2.2:5000/api/v1`.

The app requests device location only after the user taps `Use my location`.
If permission or location services are unavailable, the manual area field
remains available. Platform permission declarations belong to the separate
mobile runner setup.

The core flow supports Traditional Chinese (`zh_TW`) with English as the
fallback locale. Search results and error states include screen-reader labels.

## Checks

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The deterministic discovery smoke test can be run without provider credentials:

```bash
flutter test test/discovery_smoke_test.dart
```
