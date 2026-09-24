import KnowItWhereCore
import SwiftUI
import WidgetKit

/// Home-screen widget (FR4): the most recently updated items as
/// name → location rows. Display and shortcut only — no input or scrolling.
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
      SharedItem(id: "5", name: "Warranty papers", location: "Blue folder", updatedAt: .now),
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

  private var palette: Palette { Palette(colorScheme) }
  private var isSmall: Bool { family == .systemSmall }

  public var body: some View {
    content
      .foregroundStyle(palette.text)
      .containerBackground(for: .widget) { palette.background }
      // Space not covered by a row link opens Add (FR4.3). Small widgets only
      // support this single tap target.
      .widgetURL(DeepLink.add)
  }

  @ViewBuilder private var content: some View {
    if entry.items.isEmpty {
      VStack(spacing: 8) {
        Image(systemName: "plus.circle.fill")
          .font(.title)
          .foregroundStyle(palette.accent)
        Text("No items yet — tap to add your first")
          .font(.caption)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      VStack(alignment: .leading, spacing: isSmall ? 6 : 4) {
        header
        ForEach(SharedCache.recents(entry.items, limit: isSmall ? 3 : 5)) { item in
          if isSmall {
            StackedRow(item: item, palette: palette)
          } else {
            Link(destination: DeepLink.item(item.id)) {
              InlineRow(item: item, palette: palette)
            }
          }
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var header: some View {
    HStack {
      Text("knowitwhere")
        .font(.caption.weight(.semibold))
        .foregroundStyle(palette.accentText)
      Spacer()
      Image(systemName: "plus")
        .font(.caption.weight(.semibold))
        .foregroundStyle(palette.accent)
        .accessibilityLabel("Add item")
    }
  }
}

/// Small widget: name over location.
private struct StackedRow: View {
  let item: SharedItem
  let palette: Palette

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(item.name)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
      Label(item.location, systemImage: "mappin")
        .font(.caption)
        .labelStyle(CompactLabelStyle())
        .foregroundStyle(palette.secondary)
        .lineLimit(1)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.name), stored in \(item.location)")
  }
}

/// Medium widget: "name → location" on one line.
private struct InlineRow: View {
  let item: SharedItem
  let palette: Palette

  var body: some View {
    HStack(spacing: 6) {
      Text(item.name)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
      Image(systemName: "arrow.right")
        .font(.caption2)
        .foregroundStyle(palette.accent)
      Text(item.location)
        .font(.subheadline)
        .foregroundStyle(palette.secondary)
        .lineLimit(1)
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.name), stored in \(item.location)")
  }
}

private struct CompactLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 3) {
      configuration.icon
      configuration.title
    }
  }
}

/// Cream / ink / orange, matching the app theme (lib/theme/app_theme.dart).
struct Palette {
  let background: Color
  let text: Color
  let secondary: Color
  /// Icons and fills.
  let accent: Color
  /// Orange for small text, dark enough to read on cream.
  let accentText: Color

  init(_ scheme: ColorScheme) {
    if scheme == .dark {
      background = Color(red: 0x1F / 255, green: 0x1B / 255, blue: 0x18 / 255)
      text = Color(red: 0xFB / 255, green: 0xF8 / 255, blue: 0xF2 / 255)
      secondary = Color(red: 0xB7 / 255, green: 0xAF / 255, blue: 0xA5 / 255)
      accent = Color(red: 0xF4 / 255, green: 0x63 / 255, blue: 0x2A / 255)
      accentText = Color(red: 0xFF / 255, green: 0x9A / 255, blue: 0x6B / 255)
    } else {
      background = Color(red: 0xFB / 255, green: 0xF8 / 255, blue: 0xF2 / 255)
      text = Color(red: 0x1F / 255, green: 0x1B / 255, blue: 0x18 / 255)
      secondary = Color(red: 0x78 / 255, green: 0x72 / 255, blue: 0x6B / 255)
      accent = Color(red: 0xF4 / 255, green: 0x63 / 255, blue: 0x2A / 255)
      accentText = Color(red: 0xB4 / 255, green: 0x43 / 255, blue: 0x0F / 255)
    }
  }
}
