# Phase 4: Xcode setup on a Mac

Everything that can be done without Xcode is already in the repo:

- `ios/KnowItWhereKit` is a local Swift package with the widget UI, the Siri intent, matching and voice copy. CI tests it on macOS and builds it for iOS.
- Spotlight indexing (4.3) is already in the Runner target.
- The Runner target has the App Group entitlement and the `knowitwhere://` URL scheme.

What's left needs Xcode: two extension targets that wrap the package. This takes about 10 minutes. Before you start, run `flutter pub get` once so `ios/Flutter` is generated.

## 1. Open the workspace

Open `ios/Runner.xcworkspace` (not the `.xcodeproj`).

## 2. Add the local package

**File → Add Package Dependencies… → Add Local…** → choose `ios/KnowItWhereKit`.
When asked which products to add, **don't add any to Runner**. They go to the extensions below.

## 3. Widget extension

1. **File → New → Target… → Widget Extension**
   - Product Name: `KnowItWhereWidgetExtension` (don't use `KnowItWhereWidget`, because it clashes with the Swift type of that name)
   - Uncheck *Include Live Activity* and *Include Configuration App Intent*
   - Embed in: **Runner**. If Xcode asks to activate the scheme, choose *Cancel* (keep Runner as the active scheme)
2. Select the new target:
   - **General → Minimum Deployments:** iOS 17.0
   - **General → Frameworks and Libraries → +** → `KnowItWhereWidgetUI`
   - **Signing & Capabilities:** pick your team, **+ Capability → App Groups** → tick `group.com.AandMapps.knowitwhere`
3. Delete every Swift file Xcode generated in the new folder and add a single `KnowItWhereWidgetBundle.swift`:

```swift
import KnowItWhereWidgetUI
import SwiftUI
import WidgetKit

@main
struct KnowItWhereWidgetBundle: WidgetBundle {
  var body: some Widget {
    KnowItWhereWidget()
  }
}
```

## 4. App Intents extension (Siri)

1. **File → New → Target… → App Intents Extension**
   - Product Name: `KnowItWhereSiri` (don't use `KnowItWhereIntents`, because it clashes with the package module)
   - Embed in: **Runner**
2. Select the new target:
   - **Minimum Deployments:** iOS 17.0
   - **Frameworks and Libraries → +** → `KnowItWhereIntents`
   - **Signing & Capabilities:** team, **+ App Groups** → `group.com.AandMapps.knowitwhere`
3. Replace the generated Swift file(s) with one `KnowItWhereSiri.swift`:

```swift
import AppIntents
import KnowItWhereIntents

@main
struct KnowItWhereSiri: AppIntentsExtension {}

/// Pulls the package's intents into this extension's App Intents metadata.
struct KnowItWhereSiriPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] {
    [KnowItWhereIntentsPackage.self]
  }
}

struct KnowItWhereShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: FindItemLocationIntent(),
      phrases: [
        "Find something in \(.applicationName)",
        "Where did I put something in \(.applicationName)",
        "Ask \(.applicationName) where something is",
        "\(.applicationName), find an item",
      ],
      shortTitle: "Find an Item",
      systemImageName: "magnifyingglass"
    )
  }
}
```

## 5. Runner target

- **Signing & Capabilities:** pick your team. The App Group is already in `Runner/Runner.entitlements`; confirm it shows as ticked.
- **Build Phases:** drag **Embed Foundation Extensions** so it sits **above** **Thin Binary** and **Run Script**. Otherwise Flutter builds fail with *"Cycle inside Runner"*.

## 6. Check and push

```bash
flutter build ios --debug --no-codesign
```

Then run on a device and check:

- The widget shows recent items, updates right after an add/edit/delete, a row tap opens that item, and an empty-space tap opens Add
- "Hey Siri, find something in knowitwhere" → "What are you looking for?" → "passport" → spoken answer with no app opened
- Spotlight: search an item name; the tap opens its detail screen

Commit the `ios/` changes (new target folders, `project.pbxproj`, entitlements) and push. CI rebuilds everything.
