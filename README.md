# knowitwhere 📦

A local-only iOS app for remembering where you put physical things. Log an item's location once; find it again in under 5 seconds by typing, glancing at a home-screen widget, or asking Siri.

> **v1 success criterion:** "Hey Siri, where's my passport?" → spoken answer, zero screens opened.

Full requirements: [docs/SRS.md](docs/SRS.md) (written under the working title "Where Did I Put That?").

| | |
| --- | --- |
| Bundle ID | `com.AandMapps.knowitwhere` |
| App Group | `group.com.AandMapps.knowitwhere` |
| URL scheme | `knowitwhere://` (SRS examples use `wdipit://`) |

## Stack

| Layer | Tech |
| --- | --- |
| Main app | Flutter (Dart), Drift (SQLite) as source of truth |
| Photos | `image_picker`, stored in the app's Documents dir (relative paths only) |
| Widget | SwiftUI Widget Extension (code in `ios/KnowItWhereKit`) |
| Siri | App Intents Extension, Tier 2 "find" (code in `ios/KnowItWhereKit`) |
| System search | Core Spotlight (`ios/Runner/SpotlightPlugin.swift`) |
| Bridge | App Group shared JSON cache via `home_widget` |
| Deep links | `app_links` → `go_router` |

Fully offline. No network calls, accounts, or analytics.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Requirements | ✅ Done |
| 1 | Design | 🟡 Voice UX done; architecture, screen and widget designs await sign-off |
| 2 | Core Flutter app (FR1–FR3) | ✅ Done |
| 3 | Shared data layer, App Group, deep links | ✅ Done |
| 4 | Native widget, Siri, Spotlight | 🟡 Spotlight done; widget + Siri code ready in `ios/KnowItWhereKit`, targets need a Mac ([guide](docs/phase-4-xcode-setup.md)) |
| 5 | Testing & QA | 🟡 Unit, integration and automated accessibility tests done; device testing pending |
| 6 | Release prep | 🟡 Icon, listing copy, privacy answers, reviewer notes done; screenshots, public privacy/support URLs pending |
| 7 | Post-launch | ⏳ |

Work is tracked as GitHub issues grouped by milestone (one milestone per phase).

## Development

Requires Flutter 3.44.x (Dart 3.12). The app targets iOS 17+ (App Intents, current WidgetKit APIs).

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
  platform/             App Group shared cache, deep-link routing
  features/             home (search + list), item_form (add/edit), item_detail
  theme/                cream / charcoal / green theme
docs/SRS.md             requirements
```

### Shared cache contract (for the Swift extensions)

After every add/edit/delete, and at launch, the app writes a JSON string to
`UserDefaults(suiteName: "group.com.AandMapps.knowitwhere")` under the key
`items`, then reloads the widget timeline of kind `KnowItWhereWidget`:

```json
[{ "id": "uuid", "name": "HDMI cable", "location": "Drawer 2", "updatedAt": "2026-09-24T10:22:39.123Z" }]
```

Items are ordered most recently updated first; `updatedAt` is UTC ISO 8601.
Extensions only read this — the Drift database stays private to the app.

### Deep links

| Link | Opens |
| --- | --- |
| `knowitwhere://add` | Add item form |
| `knowitwhere://item/{id}` | Item detail |

### Docs

- [Siri voice UX](docs/siri-voice-ux.md): phrases, spoken copy, matching
- [Phase 4 Xcode setup](docs/phase-4-xcode-setup.md): adding the widget and Siri targets on a Mac
- [App Store submission](docs/app-store.md): listing, keywords, privacy, reviewer notes

### Signing (Mac)

Set your team under *Signing & Capabilities* for each target. Automatic signing
registers the App Group `group.com.AandMapps.knowitwhere`; every target (app,
widget, intents extension) must list the same group.

## Contributing

Every change should pass the SRS test: **does this make "add" or "find" faster?** If not, it goes to the v1 backlog (§9).
