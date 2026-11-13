import Foundation

/// What Siri's item parameter resolves to (FR5.3). The App Intents types that
/// call this live in the app target (ios/Runner/SiriIntents.swift); the logic
/// stays here so it is tested.
public enum ItemLookup {
  /// At most one item: v1 never asks Siri to disambiguate (SRS §9), so the
  /// matcher's single best guess is the answer.
  public static func matching(_ text: String, in items: [SharedItem]) -> [SharedItem] {
    guard let match = ItemMatcher.bestMatch(for: text, in: items) else { return [] }
    return [match.item]
  }

  public static func withIds(_ ids: [String], in items: [SharedItem]) -> [SharedItem] {
    let wanted = Set(ids)
    return items.filter { wanted.contains($0.id) }
  }
}
