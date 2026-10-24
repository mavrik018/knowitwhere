import KnowItWhereCore
import SwiftUI
import WidgetKit

/// Home-screen widget (FR4): the most recently updated items as
/// name → location cards. Display and shortcut only — no input or scrolling.
public struct KnowItWhereWidget: Widget {
  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: KnowItWhere.widgetKind, provider: ItemsProvider()) { entry in
      ItemsWidgetView(entry: entry)
    }
    .configurationDisplayName("Recent items")
    .description("Where you put things most recently.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

public struct ItemsEntry: TimelineEntry {
  public let date: Date
  public let items: [SharedItem]

  public init(date: Date, items: [SharedItem]) {
    self.date = date
    self.items = items
  }

  static let sample = ItemsEntry(
    date: .now,
    items: [
      SharedItem(id: "1", name: "Passport", location: "Desk, top drawer", updatedAt: .now),
      SharedItem(id: "2", name: "HDMI cable", location: "TV cabinet", updatedAt: .now),
      SharedItem(id: "3", name: "Spare keys", location: "Hook by the door", updatedAt: .now),
      SharedItem(id: "4", name: "Tent", location: "Loft, left side", updatedAt: .now),
    ])
}

/// Reads the shared cache. Refreshes only when the app reloads the timeline
/// after a mutation (SRS §4.4), never on a schedule.
public struct ItemsProvider: TimelineProvider {
  public init() {}

  public func placeholder(in context: Context) -> ItemsEntry {
    .sample
  }

  public func getSnapshot(in context: Context, completion: @escaping (ItemsEntry) -> Void) {
    let items = SharedCache.load()
    completion(items.isEmpty && context.isPreview ? .sample : ItemsEntry(date: .now, items: items))
  }

  public func getTimeline(in context: Context, completion: @escaping (Timeline<ItemsEntry>) -> Void) {
    let entry = ItemsEntry(date: .now, items: SharedCache.load())
    completion(Timeline(entries: [entry], policy: .never))
  }
}

public struct ItemsWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  let entry: ItemsEntry

  public init(entry: ItemsEntry) {
    self.entry = entry
  }

  public var body: some View {
    let palette = Palette(colorScheme)
    ItemsWidgetContent(entry: entry, isSmall: family == .systemSmall, palette: palette)
      .containerBackground(for: .widget) { palette.background }
      // Space outside a row opens the app, except in the empty state, which
      // invites adding the first item (FR4.3, FR4.4). Small widgets only
      // support this single tap target.
      .widgetURL(entry.items.isEmpty ? DeepLink.add : nil)
  }
}

/// The widget body without WidgetKit's container, so previews can render it.
struct ItemsWidgetContent: View {
  let entry: ItemsEntry
  let isSmall: Bool
  let palette: Palette
  /// Off for previews: `Link` only renders inside WidgetKit.
  var linksEnabled = true

  var body: some View {
    Group {
      if entry.items.isEmpty {
        EmptyContent(palette: palette)
      } else if isSmall {
        VStack(alignment: .leading, spacing: 0) {
          Header(palette: palette, showsAdd: false, linksEnabled: linksEnabled)
          Spacer(minLength: 6)
          VStack(alignment: .leading, spacing: 7) {
            ForEach(SharedCache.recents(entry.items, limit: 3)) { item in
              StackedRow(item: item, palette: palette)
            }
          }
          Spacer(minLength: 0)
        }
      } else {
        VStack(alignment: .leading, spacing: 8) {
          Header(palette: palette, showsAdd: true, linksEnabled: linksEnabled)
          LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
          ) {
            ForEach(SharedCache.recents(entry.items, limit: 4)) { item in
              WidgetLink(DeepLink.item(item.id), enabled: linksEnabled) {
                ItemCard(item: item, palette: palette)
              }
            }
          }
          Spacer(minLength: 0)
        }
      }
    }
    .foregroundStyle(palette.text)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

/// App mark and name, plus a quick Add button on the medium widget.
private struct Header: View {
  let palette: Palette
  let showsAdd: Bool
  let linksEnabled: Bool

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "archivebox.fill")
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 20, height: 20)
        .background(palette.accent, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityHidden(true)
      Text("KnowItWhere")
        .font(.caption.weight(.bold))
        .foregroundStyle(palette.accentText)
        .lineLimit(1)
      Spacer(minLength: 0)
      if showsAdd {
        WidgetLink(DeepLink.add, enabled: linksEnabled) {
          Image(systemName: "plus")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(palette.accent, in: Circle())
        }
        .accessibilityLabel("Add item")
      }
    }
  }
}

private struct WidgetLink<Label: View>: View {
  let url: URL
  let enabled: Bool
  @ViewBuilder let label: Label

  init(_ url: URL, enabled: Bool, @ViewBuilder label: () -> Label) {
    self.url = url
    self.enabled = enabled
    self.label = label()
  }

  var body: some View {
    if enabled {
      Link(destination: url) { label }
    } else {
      label
    }
  }
}

/// Small widget: name over location.
private struct StackedRow: View {
  let item: SharedItem
  let palette: Palette

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(item.name)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
      Location(text: item.location, palette: palette)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.name), stored in \(item.location)")
  }
}

/// Medium widget: a white card per item, like the board's polaroids.
private struct ItemCard: View {
  let item: SharedItem
  let palette: Palette

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(item.name)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
      Location(text: item.location, palette: palette)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(palette.cardBorder, lineWidth: 1)
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.name), stored in \(item.location)")
  }
}

private struct Location: View {
  let text: String
  let palette: Palette

  var body: some View {
    HStack(spacing: 3) {
      Image(systemName: "mappin")
        .font(.caption2.weight(.bold))
        .foregroundStyle(palette.accent)
      Text(text)
        .font(.caption)
        .foregroundStyle(palette.secondary)
        .lineLimit(1)
    }
  }
}

private struct EmptyContent: View {
  let palette: Palette

  /// A loose PNG rather than an asset catalog, so `swift test` can load it
  /// too (SwiftPM only compiles asset catalogs inside Xcode).
  private var mascot: Image {
    let url = Bundle.module.url(forResource: "mascot", withExtension: "png")
    #if canImport(UIKit)
      if let url, let image = UIImage(contentsOfFile: url.path) { return Image(uiImage: image) }
    #else
      if let url, let image = NSImage(contentsOf: url) { return Image(nsImage: image) }
    #endif
    return Image(systemName: "archivebox.fill")
  }

  var body: some View {
    VStack(spacing: 6) {
      mascot
        .resizable()
        .scaledToFit()
        .frame(height: 56)
        .accessibilityHidden(true)
      Text("Nothing saved yet")
        .font(.subheadline.weight(.semibold))
      Text("Tap to add your first")
        .font(.caption)
        .foregroundStyle(palette.accentText)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .combine)
  }
}

/// Cream / ink / orange, matching the app theme (lib/theme/app_theme.dart).
struct Palette {
  let background: Color
  /// Item cards on the medium widget.
  let card: Color
  let cardBorder: Color
  let text: Color
  let secondary: Color
  /// Icons and fills.
  let accent: Color
  /// Orange for small text, dark enough to read on the background.
  let accentText: Color

  init(_ scheme: ColorScheme) {
    accent = Color(hex: 0xF4632A)
    if scheme == .dark {
      background = Color(hex: 0x1F1B18)
      card = Color(hex: 0x2A2622)
      cardBorder = Color(hex: 0x34302B)
      text = Color(hex: 0xFBF8F2)
      secondary = Color(hex: 0xB7AFA5)
      accentText = Color(hex: 0xFF9A6B)
    } else {
      background = Color(hex: 0xFFF2E6)
      card = .white
      cardBorder = Color(hex: 0xF4D4BD)
      text = Color(hex: 0x261D17)
      secondary = Color(hex: 0x867265)
      accentText = Color(hex: 0xB4430F)
    }
  }
}

extension Color {
  fileprivate init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255)
  }
}
