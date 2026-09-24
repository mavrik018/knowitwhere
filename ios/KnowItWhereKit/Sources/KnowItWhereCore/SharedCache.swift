import Foundation

/// One entry of the flattened snapshot the Flutter app writes (SRS §5).
public struct SharedItem: Equatable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let location: String
  public let updatedAt: Date

  public init(id: String, name: String, location: String, updatedAt: Date) {
    self.id = id
    self.name = name
    self.location = location
    self.updatedAt = updatedAt
  }
}

/// Read-only access to the App Group shared cache.
public enum SharedCache {
  /// Loads and decodes the snapshot, most recently updated first.
  /// Returns an empty list if nothing has been written yet or it is unreadable.
  public static func load(
    from defaults: UserDefaults? = UserDefaults(suiteName: KnowItWhere.appGroupId)
  ) -> [SharedItem] {
    guard let json = defaults?.string(forKey: KnowItWhere.sharedCacheKey) else { return [] }
    return decode(json)
  }

  /// Decodes `[{"id", "name", "location", "updatedAt"}]`. Entries with missing
  /// fields or unparseable dates are skipped rather than failing the list.
  public static func decode(_ json: String) -> [SharedItem] {
    guard let data = json.data(using: .utf8),
      let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }

    let items = raw.compactMap { entry -> SharedItem? in
      guard let id = entry["id"] as? String,
        let name = entry["name"] as? String,
        let location = entry["location"] as? String,
        let updatedAtText = entry["updatedAt"] as? String,
        let updatedAt = parseDate(updatedAtText)
      else { return nil }
      return SharedItem(id: id, name: name, location: location, updatedAt: updatedAt)
    }
    return sortedByRecency(items)
  }

  /// The [limit] most recently updated items (widget recents, FR4.1).
  public static func recents(_ items: [SharedItem], limit: Int) -> [SharedItem] {
    Array(sortedByRecency(items).prefix(max(0, limit)))
  }

  static func sortedByRecency(_ items: [SharedItem]) -> [SharedItem] {
    items.sorted { $0.updatedAt > $1.updatedAt }
  }

  /// ISO 8601 with or without fractional seconds. Fractions longer than
  /// milliseconds (Dart can emit microseconds) are truncated first, since
  /// ISO8601DateFormatter only reads up to three digits.
  static func parseDate(_ text: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]

    let normalized = truncatingFraction(text)
    return fractional.date(from: normalized) ?? plain.date(from: normalized)
  }

  private static func truncatingFraction(_ text: String) -> String {
    guard let dot = text.firstIndex(of: ".") else { return text }
    let digitsStart = text.index(after: dot)
    let digitsEnd = text[digitsStart...].firstIndex { !$0.isNumber } ?? text.endIndex
    let digits = text[digitsStart..<digitsEnd]
    guard digits.count > 3 else { return text }
    return String(text[..<digitsStart]) + digits.prefix(3) + text[digitsEnd...]
  }
}
