import AppIntents
import KnowItWhereCore

/// Siri Tier 2 "find" (FR5): answers with the item's location out loud,
/// without opening the app.
public struct FindItemLocationIntent: AppIntent {
  public static var title: LocalizedStringResource = "Find an Item"
  public static var description = IntentDescription(
    "Tells you where you put something, without opening the app.")
  public static var openAppWhenRun: Bool = false

  /// Free text from Siri's speech-to-text (FR5.2).
  @Parameter(title: "Item", requestValueDialog: IntentDialog("What are you looking for?"))
  public var itemName: String

  public init() {}

  public init(itemName: String) {
    self.itemName = itemName
  }

  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let answer = VoiceCopy.answer(query: itemName, items: SharedCache.load())
    return .result(value: answer.location ?? "", dialog: "\(answer.spoken)")
  }
}

/// Exposes this module's intents to the app/extension that links it.
public struct KnowItWhereIntentsPackage: AppIntentsPackage {}
