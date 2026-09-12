# Nigehban (نگہبان) — Android app

Voice-first scam detection for people who may not read well. The app holds **no AI keys** — every check goes to the Nigehban backend (`social-nova-backend`).

See [PLAN.md](PLAN.md) for the full plan, pitch, and test cases.

## Build & run (teammate on PC)
```bash
flutter pub get
flutter run            # phone connected via USB with USB debugging on
flutter build apk --debug   # APK at build/app/outputs/flutter-apk/app-debug.apk
```
Requires Flutter ≥ 3.35 (Dart ≥ 3.9). `flutter analyze` must show "No issues found".

## Point the app at a backend
- Default: `AppConfig.defaultBaseUrl` in `lib/config.dart` (Vercel).
- At runtime: **long-press the Nigehban title** on the home screen → Settings → paste URL → Save. The dot next to the title turns green when the backend answers.
- Emulator + backend on the same PC: use `http://10.0.2.2:3000`.
- Real phone + backend on a laptop on the same hotspot: `http://<laptop-ip>:3000`.

## Flows
| Button | What happens |
|---|---|
| Message | bottom sheet pre-filled from clipboard → Check |
| Speak | on-device speech recognition (Urdu/English) → text → Check |
| Photo | camera/gallery → compressed → backend reads the text (any script) + edit check |
| Voice note | pick .ogg/.opus/.m4a… → backend transcribes + cloned-voice check |
| Guardian | set a family member; on 🔴/🟡 one tap opens WhatsApp with a pre-written warning |

Every screen speaks when it opens. Result screen = whole screen green/amber/red + spoken Urdu explanation + advice + lesson.

## Layers
1. `services/rules_engine.dart` — on-device keyword rules: instant spoken "careful…" hint, and an offline verdict if there is no internet.
2. Backend memory (MongoDB radar) — "others reported this too".
3. Backend brain (gpt-5.4 + Gemini + Whisper).

## Demo-phone checklist
- Install Google TTS Urdu voice: Settings → System → Languages → Text-to-speech → Google → Install voice data → Urdu. (Falls back to English automatically if missing.)
- Grant microphone permission on first "Speak".
- WhatsApp installed and logged in for the guardian alert.
- Set the guardian number once (first-run screen).
