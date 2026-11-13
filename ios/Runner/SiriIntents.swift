import AppIntents
import KnowItWhereCore

// The App Intents types live in the app target, next to the
// AppShortcutsProvider. Apple requires the provider and the intents it uses to
// be in the main app target: when they lived in the Swift package (bridged in
// with AppIntentsPackage), Siri worked in USB installs but found none of the
// shortcuts in the App Store build. The logic they call stays in
// KnowItWhereCore, where it is tested.

/// A saved item as Siri sees it, so phrases can name it directly:
/// "Where's my passport in KnowItWhere?" (one sentence, no follow-up).
struct ItemEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Item"
  static var defaultQuery = ItemEntityQuery()

  let id: String
  let name: String
  let location: String

  init(_ item: SharedItem) {
    id = item.id
    name = item.name
    location = item.location
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

/// Resolves what Siri heard to an item from the App Group shared cache.
struct ItemEntityQuery: EntityStringQuery {
  func entities(for identifiers: [String]) async throws -> [ItemEntity] {
    ItemLookup.withIds(identifiers, in: SharedCache.load()).map(ItemEntity.init)
  }

  func entities(matching string: String) async throws -> [ItemEntity] {
    ItemLookup.matching(string, in: SharedCache.load()).map(ItemEntity.init)
  }

  /// Every item, most recent first. Siri learns the spoken names from these
  /// when the app calls `updateAppShortcutParameters()`.
  func suggestedEntities() async throws -> [ItemEntity] {
    SharedCache.load().map(ItemEntity.init)
  }
}

/// Siri one-sentence "find" (FR5): speaks the item's location without
/// opening the app.
struct WhereIsItemIntent: AppIntent {
  static var title: LocalizedStringResource = "Where Is an Item"
  static var description = IntentDescription(
    "Tells you where you put a saved item, without opening the app.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Item")
  var item: ItemEntity

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    // Re-read by id: Siri may hold an entity from before the last edit.
    let answer = VoiceCopy.answer(itemId: item.id, name: item.name, items: SharedCache.load())
    return .result(value: answer.location ?? "", dialog: "\(answer.spoken)")
  }
}

/// Siri Tier 2 "find" (FR5): Siri asks for the item, then answers with its
/// location out loud, without opening the app.
struct FindItemLocationIntent: AppIntent {
  static var title: LocalizedStringResource = "Find an Item"
  static var description = IntentDescription(
    "Tells you where you put something, without opening the app.")
  static var openAppWhenRun: Bool = false

  /// Free text from Siri's speech-to-text (FR5.2).
  @Parameter(title: "Item", requestValueDialog: IntentDialog("What are you looking for?"))
  var itemName: String

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let answer = VoiceCopy.answer(query: itemName, items: SharedCache.load())
    return .result(value: answer.location ?? "", dialog: "\(answer.spoken)")
  }
}
