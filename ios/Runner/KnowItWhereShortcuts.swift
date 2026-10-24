import AppIntents
import KnowItWhereIntents

/// Siri phrases (FR5). The provider lives in the app target, not an extension,
/// because only the app can then call `updateAppShortcutParameters()` when
/// items change (see docs/siri-voice-ux.md). The intents still answer without
/// bringing the app to the foreground.
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

/// Pulls the package's intents into the app's App Intents metadata.
struct RunnerIntentsPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] {
    [KnowItWhereIntentsPackage.self]
  }
}
