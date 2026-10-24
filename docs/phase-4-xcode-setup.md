# Phase 4: Xcode setup

The widget and Siri wiring is in `ios/Runner.xcodeproj`. It was added with the `xcodeproj` Ruby gem rather than by hand, so this page records what is there and why.

## What the project contains

- **Local package** `ios/KnowItWhereKit`, added to the project as an `XCLocalSwiftPackageReference`.
- **`KnowItWhereWidgetExtension`** (WidgetKit app extension, iOS 17.0)
  - Bundle ID `com.AandMapps.knowitwhere.KnowItWhereWidget`
  - Sources: `ios/KnowItWhereWidgetExtension/KnowItWhereWidgetBundle.swift` (just the `@main` bundle; the widget itself is `KnowItWhereWidget` in the package)
  - Links `KnowItWhereWidgetUI`, `WidgetKit`, `SwiftUI`
  - `KnowItWhereWidgetExtension.entitlements` with `group.com.AandMapps.knowitwhere`
  - Uses the Flutter xcconfigs, and `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` come from `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`, so the extension's version always matches the app's (App Store validation rejects a mismatch)
- **Runner**
  - Links `KnowItWhereIntents`, and `Runner/KnowItWhereShortcuts.swift` holds the `AppShortcutsProvider`
  - Embeds the widget in **Embed Foundation Extensions**, which sits **above Thin Binary**. Otherwise Flutter builds fail with *"Cycle inside Runner"*
- All targets: team `PUS7W2V7BL`, automatic signing.

### Why there is no Siri extension

The Siri intents run in the app target, not in an App Intents extension. One-sentence phrases ("Where's my passport in KnowItWhere") need `updateAppShortcutParameters()` to be called whenever items change. Apple DTS's guidance is that the `AppShortcutsProvider` and the intents it uses must be in the main app target for the app to call that method. With `openAppWhenRun = false`, iOS runs the intent in the background and the app never comes to the foreground (FR5.3). The Flutter engine starts with the window scene, so a Siri request doesn't start Dart. Details: `docs/siri-voice-ux.md`.

## Checks

```bash
flutter build ios --debug --no-codesign
# signed, creates/updates provisioning profiles for both bundle IDs:
(cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -destination 'generic/platform=iOS' -allowProvisioningUpdates build)
```

After a build, `build/ios/iphoneos/Runner.app/PlugIns/KnowItWhereWidgetExtension.appex` must exist, and `Runner.app/Metadata.appintents/extract.actionsdata` must mention the shortcut phrases.

On a device:

- The widget shows recent items, updates right after an add/edit/delete, a row tap opens that item, an empty-space tap opens the app, and the medium widget's "+" opens Add
- "Hey Siri, find something in KnowItWhere" → "What are you looking for?" → "passport" → spoken answer, with no app opened
- Spotlight: search for an item's name; tapping the result opens its detail screen
