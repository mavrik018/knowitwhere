import XCTest

@testable import KnowItWhereCore

final class ItemLookupTests: XCTestCase {
  private let items = [
    SharedItem(id: "1", name: "Passport", location: "Desk", updatedAt: Date(timeIntervalSince1970: 3)),
    SharedItem(id: "2", name: "HDMI cable", location: "Drawer 2", updatedAt: Date(timeIntervalSince1970: 2)),
    SharedItem(id: "3", name: "Phone charger", location: "Hall", updatedAt: Date(timeIntervalSince1970: 1)),
    SharedItem(id: "4", name: "Laptop charger", location: "Bag", updatedAt: Date(timeIntervalSince1970: 4)),
  ]

  func testMatchingUsesTheMatcher() {
    let result = ItemLookup.matching("my passport", in: items)
    XCTAssertEqual(result.map(\.id), ["1"])
    XCTAssertEqual(result.first?.location, "Desk")
  }

  func testMatchingIsFuzzy() {
    XCTAssertEqual(ItemLookup.matching("hitmi cable", in: items).map(\.id), ["2"])
  }

  func testMatchingReturnsAtMostOne() {
    // Two chargers match; the most recent wins rather than asking.
    XCTAssertEqual(ItemLookup.matching("charger", in: items).map(\.id), ["4"])
  }

  func testNoMatchReturnsNothing() {
    XCTAssertTrue(ItemLookup.matching("umbrella", in: items).isEmpty)
    XCTAssertTrue(ItemLookup.matching("passport", in: []).isEmpty)
  }

  func testWithIds() {
    XCTAssertEqual(Set(ItemLookup.withIds(["2", "missing", "1"], in: items).map(\.id)), ["1", "2"])
  }
}
