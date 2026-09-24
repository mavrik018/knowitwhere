# Where Did I Put That? 📦

A local-only iOS app for remembering where you put physical things. Log an item's location once; find it again in under 5 seconds by typing, glancing at a home-screen widget, or asking Siri.

> **v1 success criterion:** "Hey Siri, where's my passport?" → spoken answer, zero screens opened.

Full requirements: [docs/SRS.md](docs/SRS.md).

## Stack

| Layer | Tech |
| --- | --- |
| Main app | Flutter (Dart), Drift (SQLite) as source of truth |
| Photos | `image_picker`, stored in the app's Documents dir (relative paths only) |
| Widget | SwiftUI Widget Extension *(Phase 4)* |
| Siri | App Intents Extension, Tier 2 "find" *(Phase 4)* |
| System search | Core Spotlight *(Phase 4)* |
| Bridge | App Group shared JSON cache via `home_widget` *(Phase 3)* |

Fully offline. No network calls, accounts, or analytics.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Requirements | ✅ Done |
| 1 | Design | ⏳ |
| 2 | Core Flutter app (FR1–FR3) | 🚧 In progress |
| 3 | Shared data layer, App Group, deep links | ⏳ |
| 4 | Native widget, Siri, Spotlight | ⏳ |
| 5 | Testing & QA | ⏳ |
| 6 | Release prep | ⏳ |
| 7 | Post-launch | ⏳ |

Work is tracked as GitHub issues grouped by milestone (one milestone per phase).

## Development

Requires Flutter 3.44.x (Dart 3.12).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after changing Drift tables
flutter analyze
flutter test
```

Running:

- **iOS** (Mac with Xcode): `flutter run` with a simulator or device attached.
- **Windows** (dev convenience only, not a shipping target): `flutter run -d windows`. Camera capture is unavailable there; the photo picker falls back to a file dialog.

Generated Drift code (`*.g.dart`) is committed so the app builds without running codegen.

### Project layout

```
lib/
  app.dart              MaterialApp + routes (/, /add, /item/:id, /item/:id/edit)
  data/                 Drift DB, Item model, repository, photo storage
  features/             home (search + list), item_form (add/edit), item_detail
  theme/                cream / charcoal / green theme
docs/SRS.md             requirements
```

### Mac-only steps (Phases 3–4)

App Group provisioning, the Widget Extension and the App Intents Extension are Xcode targets and have to be added on a Mac. See the Phase 3/4 issues.

## Contributing

Every change should pass the SRS test: **does this make "add" or "find" faster?** If not, it goes to the v1 backlog (§9).
