import Foundation

/// What Siri says (SRS Phase 1.4, docs/siri-voice-ux.md).
public enum VoiceCopy {
  public static let askForItem = "What are you looking for?"
  public static let nothingSaved = "You haven't saved anything in KnowItWhere yet."

  public static func found(item: SharedItem) -> String {
    "\(item.name) is here: \(sentence(item.location))"
  }

  public static func found(_ match: ItemMatch) -> String {
    var text = found(item: match.item)
    if match.otherMatches > 0 {
      text += " That's the most recent of \(match.otherMatches + 1) matches."
    }
    return text
  }

  public static func notFound(_ query: String) -> String {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "I couldn't find anything matching that." }
    return "I couldn't find anything matching \"\(trimmed)\"."
  }

  /// The full Siri answer plus the location to return as the intent's value
  /// (nil when nothing matched).
  public static func answer(query: String, items: [SharedItem]) -> (spoken: String, location: String?) {
    guard !items.isEmpty else { return (nothingSaved, nil) }
    guard let match = ItemMatcher.bestMatch(for: query, in: items) else {
      return (notFound(query), nil)
    }
    return (found(match), match.item.location)
  }

  /// The answer for an item Siri already resolved (one-sentence phrase).
  /// Looked up by id so an edit since Siri last fetched names is reflected;
  /// an item deleted in the meantime is reported as not found.
  public static func answer(itemId: String, name: String, items: [SharedItem]) -> (
    spoken: String, location: String?
  ) {
    guard let item = items.first(where: { $0.id == itemId }) else {
      return (notFound(name), nil)
    }
    return (found(item: item), item.location)
  }

  /// Ends the text with exactly one full stop.
  private static func sentence(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let last = trimmed.last else { return "" }
    return ".!?".contains(last) ? trimmed : trimmed + "."
  }
}
