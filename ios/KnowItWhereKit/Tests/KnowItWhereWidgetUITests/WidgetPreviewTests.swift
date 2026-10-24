import KnowItWhereCore
import SwiftUI
import XCTest

@testable import KnowItWhereWidgetUI

/// Renders the widget in every state. Always checks that rendering works;
/// with WIDGET_PREVIEW_DIR set it also writes PNGs there (docs/screens has
/// the committed ones), e.g.
/// `WIDGET_PREVIEW_DIR=../../docs/screens swift test --filter WidgetPreviewTests`
@MainActor
final class WidgetPreviewTests: XCTestCase {
  // Home-screen widget sizes on a 6.9" iPhone, in points.
  private let small = CGSize(width: 170, height: 170)
  private let medium = CGSize(width: 364, height: 170)

  private let items = [
    SharedItem(id: "1", name: "Passport", location: "Bedside table, top drawer", updatedAt: Date(timeIntervalSince1970: 6)),
    SharedItem(id: "2", name: "Spare keys", location: "Entry console bowl", updatedAt: Date(timeIntervalSince1970: 5)),
    SharedItem(id: "3", name: "HDMI cable", location: "TV cabinet", updatedAt: Date(timeIntervalSince1970: 4)),
    SharedItem(id: "4", name: "Winter jacket", location: "Hall closet, top bin", updatedAt: Date(timeIntervalSince1970: 3)),
    SharedItem(id: "5", name: "Tent", location: "Loft, left side", updatedAt: Date(timeIntervalSince1970: 2)),
  ]

  func testRendersEveryState() throws {
    for scheme in [ColorScheme.light, .dark] {
      for (family, size) in [("small", small), ("medium", medium)] {
        for (state, list) in [("items", items), ("empty", [])] {
          let name = "widget_\(family)_\(state)_\(scheme == .dark ? "dark" : "light")"
          let data = try XCTUnwrap(render(list, isSmall: family == "small", scheme: scheme, size: size), name)
          XCTAssertGreaterThan(data.count, 0)
          if let dir = ProcessInfo.processInfo.environment["WIDGET_PREVIEW_DIR"] {
            try data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
          }
        }
      }
    }
  }

  private func render(_ items: [SharedItem], isSmall: Bool, scheme: ColorScheme, size: CGSize) -> Data? {
    let palette = Palette(scheme)
    let view = ItemsWidgetContent(
      entry: ItemsEntry(date: .now, items: items), isSmall: isSmall, palette: palette,
      linksEnabled: false
    )
    .padding(16)
    .frame(width: size.width, height: size.height)
    .background(palette.background)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .environment(\.colorScheme, scheme)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    guard let image = renderer.cgImage else { return nil }
    let rep = NSBitmapImageRep(cgImage: image)
    return rep.representation(using: .png, properties: [:])
  }
}
