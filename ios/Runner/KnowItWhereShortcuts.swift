import AppIntents
import Flutter
import KnowItWhereIntents

/// Siri phrases (FR5). The provider lives in the app target, not an extension,
/// because only then can the app call `updateAppShortcutParameters()` when
/// items change (see docs/siri-voice-ux.md). The intents still answer without
/// bringing the app to the foreground.
struct KnowItWhereShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    // One sentence: Siri resolves the item name from the phrase itself.
    // "Where's my …" and "Find my …" on their own belong to Find My, so the
    // phrases that lead with the app name or "where did I put" come first
    // and there is no "Find my {item}" (see docs/siri-voice-ux.md).
    AppShortcut(
      intent: WhereIsItemIntent(),
      phrases: [
        "Ask \(.applicationName) where my \(\.$item) is",
        "Ask \(.applicationName) where I put my \(\.$item)",
        "\(.applicationName), where's my \(\.$item)",
        "\(.applicationName), where is my \(\.$item)",
        "Where did I put my \(\.$item) in \(.applicationName)",
        "Where did I leave my \(\.$item) in \(.applicationName)",
        "Where's my \(\.$item) in \(.applicationName)",
        "Where is my \(\.$item) in \(.applicationName)",
      ],
      shortTitle: "Where Is It?",
      systemImageName: "mappin.and.ellipse"
    )
    // Fallback: Siri asks "What are you looking for?" (free text).
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

/// Dart calls `refresh` after every mutation (once the shared cache is
/// written) so Siri re-reads the item names it listens for.
final class SiriShortcutsPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "knowitwhere/siri", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SiriShortcutsPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "refresh" else {
      result(FlutterMethodNotImplemented)
      return
    }
    KnowItWhereShortcuts.updateAppShortcutParameters()
    result(nil)
  }
}
