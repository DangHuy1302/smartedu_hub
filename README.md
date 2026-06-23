# smartedu_hub

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run the app on Web (Chrome)

Follow these steps so teammates can clone and run the project locally on the web:

1. Install Flutter (stable) and ensure it's on PATH. Verify with `flutter --version`.
2. From the project root run:

```bash
flutter pub get
flutter run -d chrome
```

3. Local secret key: this project uses `lib/secret.dart` for local API keys (ignored by Git). Copy `lib/secret.example.dart` to `lib/secret.dart` and fill your Google Cloud API key if you need Vision/Translation/TTS.

4. If the app hits Google API errors (403), check Google Cloud Console: enable Billing, enable Cloud Vision / Cloud Translation / Text-to-Speech APIs, and verify API key restrictions.

Notes:
- `pubspec.lock` is committed to lock dependency versions for consistent local builds.
- Do NOT commit `lib/secret.dart` — keep keys local.

