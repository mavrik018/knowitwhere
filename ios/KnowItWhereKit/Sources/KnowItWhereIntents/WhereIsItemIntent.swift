import AppIntents
import KnowItWhereCore

/// A saved item as Siri sees it, so phrases can name it directly:
/// "Where's my passport in KnowItWhere?" (one sentence, no follow-up).
public struct ItemEntity: AppEntity {
  public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Item"
  public static var defaultQuery = ItemEntityQuery()

  public let id: String
  public let name: String
  public let location: String

  public init(id: String, name: String, location: String) {
    self.id = id
    self.name = name
    self.location = location
  }

  init(_ item: SharedItem) {
    self.init(id: item.id, name: item.name, location: item.location)
  }

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

/// Resolves what Siri heard to an item from the App Group shared cache.
public struct ItemEntityQuery: EntityStringQuery {
  public init() {}

  public func entities(for identifiers: [String]) async throws -> [ItemEntity] {
    Self.entities(for: identifiers, in: SharedCache.load())
  }

  public func entities(matching string: String) async throws -> [ItemEntity] {
    Self.entities(matching: string, in: SharedCache.load())
  }

  /// Every item, most recent first. Siri learns the spoken names from these
  /// when the app calls `updateAppShortcutParameters()`.
  public func suggestedEntities() async throws -> [ItemEntity] {
    SharedCache.load().map(ItemEntity.init)
  }

  static func entities(for identifiers: [String], in items: [SharedItem]) -> [ItemEntity] {
    let wanted = Set(identifiers)
    return items.filter { wanted.contains($0.id) }.map(ItemEntity.init)
  }

  /// At most one entity: v1 never asks Siri to disambiguate (SRS §9), so the
  /// matcher's single best guess is the answer.
  static func entities(matching string: String, in items: [SharedItem]) -> [ItemEntity] {
    guard let match = ItemMatcher.bestMatch(for: string, in: items) else { return [] }
    return [ItemEntity(match.item)]
  }
}

/// Siri one-sentence "find" (FR5): speaks the item's location without
/// opening the app.
public struct WhereIsItemIntent: AppIntent {
  public static var title: LocalizedStringResource = "Where Is an Item"
  public static var description = IntentDescription(
    "Tells you where you put a saved item, without opening the app.")
  public static var openAppWhenRun: Bool = false

  @Parameter(title: "Item")
  public var item: ItemEntity

  public init() {}

  public init(item: ItemEntity) {
    self.item = item
  }

  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    // Re-read by id: Siri may hold an entity from before the last edit.
    let answer = VoiceCopy.answer(itemId: item.id, name: item.name, items: SharedCache.load())
    return .result(value: answer.location ?? "", dialog: "\(answer.spoken)")
  }
}
