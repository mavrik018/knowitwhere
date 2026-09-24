import Foundation

/// What Siri says (SRS Phase 1.4, docs/siri-voice-ux.md).
public enum VoiceCopy {
  public static let askForItem = "What are you looking for?"
  public static let nothingSaved = "You haven't saved anything in knowitwhere yet."

  public static func found(_ match: ItemMatch) -> String {
    var text = "\(match.item.name) is here: \(sentence(match.item.location))"
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

  /// Ends the text with exactly one full stop.
  private static func sentence(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let last = trimmed.last else { return "" }
    return ".!?".contains(last) ? trimmed : trimmed + "."
  }
}
