import 'package:flutter/widgets.dart';

/// Layout tier from the window width, never the device model: an iPad in
/// Slide Over or 1/3 Split View is as narrow as a phone, and Stage Manager
/// windows can be any size.
enum WindowSize {
  /// < 600: phone layout (also iPad Slide Over and 1/3 Split View).
  compact,

  /// 600–899: navigation rail, grid, stacked detail (iPad portrait, 1/2 split).
  medium,

  /// ≥ 900: sidebar, grid, side inspector (iPad landscape, large windows).
  expanded;

  static const mediumMinWidth = 600.0;
  static const expandedMinWidth = 900.0;

  static WindowSize ofWidth(double width) {
    if (width >= expandedMinWidth) return expanded;
    if (width >= mediumMinWidth) return medium;
    return compact;
  }

  static WindowSize of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  /// Tablet-class layouts: medium and expanded.
  bool get isWide => this != compact;
}

/// iPad layout metrics. These are plain logical pixels: on wide windows
/// ScreenUtil runs at scale 1.0, so type and touch targets stay phone-sized
/// and only the spacing and structure change.
abstract final class TabletMetrics {
  static const gutter = 32.0;
  static const sidebarWidth = 264.0;
  static const inspectorWidth = 400.0;

  /// Max width for reading text, forms and single-column lists.
  static const readableWidth = 760.0;

  /// Target width of one board card; the column count follows from it.
  static const boardCardWidth = 190.0;

  /// Add/edit modal card.
  static const dialogMaxWidth = 560.0;
}
