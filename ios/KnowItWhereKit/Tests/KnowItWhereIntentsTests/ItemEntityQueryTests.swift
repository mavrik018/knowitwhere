import KnowItWhereCore
import XCTest

@testable import KnowItWhereIntents

final class ItemEntityQueryTests: XCTestCase {
  private let items = [
    SharedItem(id: "1", name: "Passport", location: "Desk", updatedAt: Date(timeIntervalSince1970: 3)),
    SharedItem(id: "2", name: "HDMI cable", location: "Drawer 2", updatedAt: Date(timeIntervalSince1970: 2)),
    SharedItem(id: "3", name: "Phone charger", location: "Hall", updatedAt: Date(timeIntervalSince1970: 1)),
    SharedItem(id: "4", name: "Laptop charger", location: "Bag", updatedAt: Date(timeIntervalSince1970: 4)),
  ]

  func testMatchingUsesTheMatcher() {
    let result = ItemEntityQuery.entities(matching: "my passport", in: items)
    XCTAssertEqual(result.map(\.id), ["1"])
    XCTAssertEqual(result.first?.location, "Desk")
  }

  func testMatchingIsFuzzy() {
    XCTAssertEqual(ItemEntityQuery.entities(matching: "hitmi cable", in: items).map(\.id), ["2"])
  }

  func testMatchingReturnsAtMostOne() {
    // Two chargers match; the most recent wins rather than asking.
    XCTAssertEqual(ItemEntityQuery.entities(matching: "charger", in: items).map(\.id), ["4"])
  }

  func testNoMatchReturnsNothing() {
    XCTAssertTrue(ItemEntityQuery.entities(matching: "umbrella", in: items).isEmpty)
    XCTAssertTrue(ItemEntityQuery.entities(matching: "passport", in: []).isEmpty)
  }

  func testEntitiesForIdentifiers() {
    let result = ItemEntityQuery.entities(for: ["2", "missing", "1"], in: items)
    XCTAssertEqual(Set(result.map(\.id)), ["1", "2"])
  }

  func testDisplayNameIsTheItemName() {
    let entity = ItemEntity(id: "1", name: "Passport", location: "Desk")
    XCTAssertEqual(String(localized: entity.displayRepresentation.title), "Passport")
  }
}
