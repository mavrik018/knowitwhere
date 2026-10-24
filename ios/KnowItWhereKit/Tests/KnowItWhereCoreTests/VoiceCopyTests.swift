import XCTest

@testable import KnowItWhereCore

final class VoiceCopyTests: XCTestCase {
  private let passport = SharedItem(
    id: "1", name: "Passport", location: "Desk, top drawer",
    updatedAt: Date(timeIntervalSince1970: 100))

  func testFoundSpeaksNameAndLocation() {
    let answer = VoiceCopy.answer(query: "passport", items: [passport])
    XCTAssertEqual(answer.spoken, "Passport is here: Desk, top drawer.")
    XCTAssertEqual(answer.location, "Desk, top drawer")
  }

  func testFoundUsesTheSavedNameForFuzzyMatches() {
    let cable = SharedItem(
      id: "2", name: "HDMI cable", location: "Drawer 2", updatedAt: Date(timeIntervalSince1970: 1))
    XCTAssertEqual(
      VoiceCopy.answer(query: "hitmi cable", items: [cable]).spoken,
      "HDMI cable is here: Drawer 2.")
  }

  func testLocationPunctuationIsNotDoubled() {
    let item = SharedItem(
      id: "3", name: "Keys", location: "On the hook!", updatedAt: Date(timeIntervalSince1970: 1))
    XCTAssertEqual(VoiceCopy.answer(query: "keys", items: [item]).spoken, "Keys is here: On the hook!")
  }

  func testAmbiguousMentionsTheOtherMatches() {
    let a = SharedItem(id: "a", name: "Phone charger", location: "Drawer", updatedAt: Date(timeIntervalSince1970: 1))
    let b = SharedItem(id: "b", name: "Laptop charger", location: "Backpack", updatedAt: Date(timeIntervalSince1970: 2))
    XCTAssertEqual(
      VoiceCopy.answer(query: "charger", items: [a, b]).spoken,
      "Laptop charger is here: Backpack. That's the most recent of 2 matches.")
  }

  func testNotFoundEchoesWhatWasHeard() {
    let answer = VoiceCopy.answer(query: "umbrella", items: [passport])
    XCTAssertEqual(answer.spoken, "I couldn't find anything matching \"umbrella\".")
    XCTAssertNil(answer.location)
    XCTAssertEqual(VoiceCopy.notFound("  "), "I couldn't find anything matching that.")
  }

  func testNothingSavedYet() {
    XCTAssertEqual(
      VoiceCopy.answer(query: "passport", items: []).spoken,
      "You haven't saved anything in KnowItWhere yet.")
  }

  func testAnswerForResolvedItemUsesTheCurrentLocation() {
    let moved = SharedItem(
      id: "1", name: "Passport", location: "Safe", updatedAt: Date(timeIntervalSince1970: 200))
    let answer = VoiceCopy.answer(itemId: "1", name: "Passport", items: [moved])
    XCTAssertEqual(answer.spoken, "Passport is here: Safe.")
    XCTAssertEqual(answer.location, "Safe")
  }

  func testAnswerForDeletedItemIsNotFound() {
    let answer = VoiceCopy.answer(itemId: "gone", name: "Tent", items: [passport])
    XCTAssertEqual(answer.spoken, "I couldn't find anything matching \"Tent\".")
    XCTAssertNil(answer.location)
  }

  func testFoundItem() {
    XCTAssertEqual(VoiceCopy.found(item: passport), "Passport is here: Desk, top drawer.")
  }
}
