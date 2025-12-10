# PrepPilot AI

Mobile app for English exams preparation (IELTS & TOEFL). Leverages AI to generate practice tasks, evaluate answers, and provide feedback across Reading, Writing, Listening, and Speaking.

## Tech Stack
Flutter (Material 3), Riverpod, get_it (DI), Freezed + JSON serialization, Dio (network), just_audio / record / speech_to_text / flutter_tts (audio & speech), shared_preferences (local storage), dotenv for API keys.

## Release APK
https://github.com/Erp4759/PrepPilot-AI/releases/

## Structure (early scaffold)
```
lib/
	main.dart                # Entry -> bootstrap
	src/
		bootstrap/             # env + guarded run
		app/                   # App root widget
		core/
			theme/               # Theming
			router/              # App router (placeholder)
			ai/                  # (future) AI service abstractions
		features/
			reading/             # Reading practice module
			writing/             # (planned)
			listening/           # (planned)
			speaking/            # (planned)
```

## Environment Variables
Create a `.env` (NOT committed) with values like:
```
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
```

## Run
```
flutter pub get
flutter run
```

## AI Agent
- Location: `lib/src/services/ai_agent.dart`
- Default model: `gpt-4o-mini` (cost‑efficient). Reads `CHATGPT_API_KEY` from `env`.

Usage:
```dart
import 'package:prep_pilot_ai/src/services/ai_agent.dart';

// Quick chat
final reply = await aiChat(system: 'Be concise.', user: 'Summarize this text.');

// Strict JSON
final result = await aiJson<Map<String, dynamic>>(
	userPrompt: 'Return {"topic":"...","items":[...]} as JSON only',
);

// Custom instance / model
final agent = AiAgent(model: 'gpt-4o-mini');
final text = await agent.respond(user: 'Hello');
```

## Next Steps
- Implement unified AIService abstraction.
- Add domain models for tasks & evaluations (Freezed).
- Expand router with feature routes.
- Integrate audio recording & TTS for Speaking.
- Add persistence for progress tracking.

---
Early scaffold generated automatically; refine as features land.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
<!-- Merged remote short description with detailed scaffold -->
