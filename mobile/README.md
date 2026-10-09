# Mobile

iOS/Android Flutter client workspace.

Flutter 3.47.6 is intended to run in the project DevContainer. SDK setup is
tracked separately; do not install project SDKs on the Mac host. The Mac host
only supplies Xcode for iOS simulator, build, signing, and distribution work.

Set `API_BASE_URL` with `--dart-define` when running the app. For the Android
emulator, use the host alias `http://10.0.2.2:5000/api/v1`.

## Checks

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
