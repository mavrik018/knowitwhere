import XCTest

@testable import KnowItWhereCore

final class SharedCacheTests: XCTestCase {
  func testDecodesSnapshotMostRecentFirst() {
    let json = """
      [
        {"id": "1", "name": "Passport", "location": "Desk", "updatedAt": "2026-01-01T10:00:00.000Z"},
        {"id": "2", "name": "Keys", "location": "Hook", "updatedAt": "2026-01-02T10:00:00.000Z"}
      ]
      """
    XCTAssertEqual(SharedCache.decode(json).map(\.id), ["2", "1"])
  }

  func testParsesMillisecondsMicrosecondsAndWholeSeconds() {
    let expected = Date(timeIntervalSince1970: 1_767_225_600.123)  // 2026-01-01T00:00:00.123Z
    let ms = SharedCache.parseDate("2026-01-01T00:00:00.123Z")
    let us = SharedCache.parseDate("2026-01-01T00:00:00.123456Z")
    XCTAssertEqual(ms!.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 0.001)
    XCTAssertEqual(us!.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 0.001)
    XCTAssertNotNil(SharedCache.parseDate("2026-01-01T00:00:00Z"))
    XCTAssertNil(SharedCache.parseDate("yesterday"))
  }

  func testSkipsBrokenEntriesAndSurvivesGarbage() {
    let json = """
      [
        {"id": "1", "name": "Passport", "location": "Desk", "updatedAt": "2026-01-01T10:00:00Z"},
        {"id": "2", "name": "No location", "updatedAt": "2026-01-01T10:00:00Z"},
        {"id": "3", "name": "Bad date", "location": "x", "updatedAt": "soon"}
      ]
      """
    XCTAssertEqual(SharedCache.decode(json).map(\.id), ["1"])
    XCTAssertEqual(SharedCache.decode("not json"), [])
    XCTAssertEqual(SharedCache.decode("{}"), [])
  }

  func testLoadsFromUserDefaultsSuite() {
    let suite = "knowitwhere.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    XCTAssertEqual(SharedCache.load(from: defaults), [])
    defaults.set(
      #"[{"id":"1","name":"Tent","location":"Loft","updatedAt":"2026-01-01T00:00:00Z"}]"#,
      forKey: KnowItWhere.sharedCacheKey)
    XCTAssertEqual(SharedCache.load(from: defaults).map(\.name), ["Tent"])
    XCTAssertEqual(SharedCache.load(from: nil), [])
  }

  func testRecentsTakesTheNewestItems() {
    let items = (0..<8).map {
      SharedItem(id: "\($0)", name: "n\($0)", location: "l", updatedAt: Date(timeIntervalSince1970: Double($0)))
    }
    XCTAssertEqual(SharedCache.recents(items, limit: 3).map(\.id), ["7", "6", "5"])
    XCTAssertEqual(SharedCache.recents(items, limit: 0), [])
  }

  func testDeepLinksMatchTheFlutterRoutes() {
    XCTAssertEqual(DeepLink.add.absoluteString, "knowitwhere://add")
    XCTAssertEqual(DeepLink.item("abc-123").absoluteString, "knowitwhere://item/abc-123")
  }
}
