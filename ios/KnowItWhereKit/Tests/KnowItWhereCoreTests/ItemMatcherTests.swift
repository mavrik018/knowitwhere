import XCTest

@testable import KnowItWhereCore

final class ItemMatcherTests: XCTestCase {
  private var minutes = 0

  /// Each call is one minute newer than the previous one.
  private func item(_ name: String, _ location: String = "somewhere") -> SharedItem {
    minutes += 1
    return SharedItem(
      id: name, name: name, location: location,
      updatedAt: Date(timeIntervalSince1970: Double(minutes * 60)))
  }

  private func match(_ query: String, _ items: [SharedItem]) -> ItemMatch? {
    ItemMatcher.bestMatch(for: query, in: items)
  }

  func testExactMatchIsCaseAndAccentInsensitive() {
    let items = [item("Passport"), item("Café receipt")]
    XCTAssertEqual(match("PASSPORT", items)?.item.name, "Passport")
    XCTAssertEqual(match("cafe receipt", items)?.kind, .exact)
  }

  func testSpokenFillerWordsAreIgnored() {
    let items = [item("Passport")]
    XCTAssertEqual(match("my passport", items)?.kind, .exact)
    XCTAssertEqual(match("Where's my passport?", items)?.kind, .exact)
    XCTAssertEqual(match("the passport", items)?.kind, .exact)
  }

  func testExactBeatsSubstringForCloseNames() {
    // SRS §11 risk: "charger" vs "charger 2".
    let items = [item("Charger"), item("Charger 2")]
    XCTAssertEqual(match("charger", items)?.item.name, "Charger")
    XCTAssertEqual(match("charger 2", items)?.item.name, "Charger 2")
  }

  func testSubstringMatchesEitherWay() {
    let items = [item("HDMI cable"), item("Passport")]
    XCTAssertEqual(match("hdmi", items)?.item.name, "HDMI cable")
    XCTAssertEqual(match("hdmi", items)?.kind, .substring)
    XCTAssertEqual(match("my old passport", items)?.item.name, "Passport")
  }

  func testFuzzyCatchesSpeechToTextNearMisses() {
    let items = [item("HDMI cable"), item("Passport"), item("Umbrella")]
    let result = match("hitmi cable", items)
    XCTAssertEqual(result?.item.name, "HDMI cable")
    XCTAssertEqual(result?.kind, .fuzzy)
    XCTAssertEqual(match("pasport", items)?.item.name, "Passport")
    XCTAssertEqual(match("umbrela", items)?.item.name, "Umbrella")
  }

  func testFuzzyMatchesAWordWithinALongerName() {
    let items = [item("HDMI cable")]
    XCTAssertEqual(match("hitmi", items)?.item.name, "HDMI cable")
  }

  func testNothingCloseMeansNoMatch() {
    let items = [item("HDMI cable"), item("Passport")]
    XCTAssertNil(match("umbrella", items))
    XCTAssertNil(match("", items))
    XCTAssertNil(match("   ", items))
    XCTAssertNil(match("passport", []))
  }

  func testAmbiguousMatchesReturnTheMostRecent() {
    let old = item("Phone charger", "Kitchen drawer")
    let recent = item("Laptop charger", "Backpack")
    let result = match("charger", [old, recent])
    XCTAssertEqual(result?.item.location, "Backpack")
    XCTAssertEqual(result?.otherMatches, 1)
  }

  func testLevenshtein() {
    XCTAssertEqual(ItemMatcher.levenshtein("kitten", "sitting"), 3)
    XCTAssertEqual(ItemMatcher.levenshtein("", "abc"), 3)
    XCTAssertEqual(ItemMatcher.levenshtein("same", "same"), 0)
  }
}
