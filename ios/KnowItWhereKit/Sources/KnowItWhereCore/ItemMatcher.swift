import Foundation

/// The item Siri should answer with.
public struct ItemMatch: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    case exact
    case substring
    case fuzzy
  }

  public let item: SharedItem
  public let kind: Kind
  /// How many other items matched equally well. v1 answers with the most
  /// recently updated one instead of asking (FR5.3, documented limitation).
  public let otherMatches: Int
}

/// Matches a spoken item name against saved items (FR5.3).
///
/// Tiers, first hit wins: exact name → substring (either way round) → fuzzy
/// (edit-distance similarity, for speech-to-text near misses such as
/// "hitmi cable" → "HDMI cable"). Within a tier the most recent item wins.
public enum ItemMatcher {
  /// Minimum similarity (0...1) for a fuzzy match.
  public static let fuzzyThreshold = 0.6

  /// Leading words people say that aren't part of the item name.
  static let fillerWords: Set<String> = [
    "my", "the", "a", "an", "our", "where", "wheres", "is", "are", "did", "i", "put",
  ]

  public static func bestMatch(for query: String, in items: [SharedItem]) -> ItemMatch? {
    let q = normalize(query)
    guard !q.isEmpty else { return nil }
    let candidates = SharedCache.sortedByRecency(items).map { ($0, normalize($0.name)) }

    let exact = candidates.filter { $0.1 == q }.map(\.0)
    if let match = pick(exact, .exact) { return match }

    let substring = candidates.filter { _, name in
      guard !name.isEmpty else { return false }
      // Reverse containment ("my old passport" ⊃ "passport") needs a
      // non-trivial name, or one-letter names would match everything.
      return name.contains(q) || (name.count >= 3 && q.contains(name))
    }.map(\.0)
    if let match = pick(substring, .substring) { return match }

    var bestScore = fuzzyThreshold
    var best: [SharedItem] = []
    for (item, name) in candidates {
      let score = similarity(q, name)
      if score > bestScore + 1e-9 {
        bestScore = score
        best = [item]
      } else if abs(score - bestScore) <= 1e-9 {
        best.append(item)
      }
    }
    return pick(best, .fuzzy)
  }

  /// `candidates` must already be ordered most recent first.
  private static func pick(_ candidates: [SharedItem], _ kind: ItemMatch.Kind) -> ItemMatch? {
    guard let first = candidates.first else { return nil }
    return ItemMatch(item: first, kind: kind, otherMatches: candidates.count - 1)
  }

  /// Lowercased, accent-free, punctuation-free words with leading filler
  /// words ("my", "the", "where's"...) removed.
  static func normalize(_ text: String) -> String {
    let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
      .replacingOccurrences(of: "'", with: "")
      .replacingOccurrences(of: "’", with: "")
    var words = folded.components(separatedBy: CharacterSet.alphanumerics.inverted)
      .filter { !$0.isEmpty }
    while let first = words.first, fillerWords.contains(first), words.count > 1 {
      words.removeFirst()
    }
    return words.joined(separator: " ")
  }

  /// Best of whole-name similarity and similarity against any run of the
  /// name's words with the same word count as the query, so "hitmi" can
  /// still find "HDMI cable".
  static func similarity(_ query: String, _ name: String) -> Double {
    var best = ratio(query, name)
    let nameWords = name.split(separator: " ").map(String.init)
    let width = query.split(separator: " ").count
    if width < nameWords.count {
      for start in 0...(nameWords.count - width) {
        let window = nameWords[start..<(start + width)].joined(separator: " ")
        best = max(best, ratio(query, window))
      }
    }
    return best
  }

  private static func ratio(_ a: String, _ b: String) -> Double {
    let longest = max(a.count, b.count)
    guard longest > 0 else { return 1 }
    return 1 - Double(levenshtein(a, b)) / Double(longest)
  }

  static func levenshtein(_ a: String, _ b: String) -> Int {
    let a = Array(a)
    let b = Array(b)
    if a.isEmpty { return b.count }
    if b.isEmpty { return a.count }
    var previous = Array(0...b.count)
    var current = [Int](repeating: 0, count: b.count + 1)
    for i in 1...a.count {
      current[0] = i
      for j in 1...b.count {
        let cost = a[i - 1] == b[j - 1] ? 0 : 1
        current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
      }
      swap(&previous, &current)
    }
    return previous[b.count]
  }
}
