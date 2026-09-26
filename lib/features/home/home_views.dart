import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/database.dart';
import '../../layout/hover_lift.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_label.dart';
import 'grouping.dart';
import 'item_card.dart';

/// Callbacks shared by every home view.
class ItemActions {
  const ItemActions({required this.open, required this.delete});

  final void Function(Item item) open;
  final void Function(Item item) delete;
}

EdgeInsets get _pagePadding => EdgeInsets.symmetric(horizontal: 20.w);

/// Board view: pinned-photo cards grouped by recency.
///
/// Phones get two columns (one at large text sizes so names stay readable).
/// iPad passes [columns], its own [padding], the [selectedId] shown in the
/// inspector, and [hover] for pointer lift.
List<Widget> boardSlivers(
  BuildContext context,
  List<Item> items,
  ItemActions actions, {
  int? columns,
  EdgeInsets? padding,
  String? selectedId,
  bool hover = false,
}) {
  final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.6;
  final cols = columns ?? (largeText ? 1 : 2);
  final pad = padding ?? _pagePadding;
  Widget boardCard(Item item, int i, int row, int cols) {
    final card = ItemBoardCard(
      item: item,
      // Alternate a slight tilt so the board looks pinned by hand.
      tiltAngle: cols > 1
          ? (i.isEven ? -0.024 : 0.022)
          : (row.isEven ? -0.018 : 0.018),
      selected: item.id == selectedId,
      onTap: () => actions.open(item),
      onDelete: () => actions.delete(item),
    );
    return hover ? HoverLift(child: card) : card;
  }

  return [
    for (final section in groupByRecency(items, DateTime.now())) ...[
      _sectionHeader(
        SectionLabel(section.title, count: section.items.length),
        padding: pad,
      ),
      SliverPadding(
        padding: pad,
        sliver: SliverList.separated(
          itemCount: (section.items.length / cols).ceil(),
          separatorBuilder: (_, _) => SizedBox(height: 18.h),
          itemBuilder: (context, row) {
            final cells = section.items.skip(row * cols).take(cols);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in cells.indexed) ...[
                    if (i > 0) SizedBox(width: 12.w),
                    Expanded(child: boardCard(item, i, row, cols)),
                  ],
                  // Keep the last row's cards the same width as the rest.
                  for (var i = cells.length; i < cols; i++) ...[
                    SizedBox(width: 12.w),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ],
  ];
}

/// Layout options for the list views on iPad; phones use the defaults.
class ListLayout {
  const ListLayout({this.padding, this.maxWidth, this.selectedId});

  /// Horizontal page padding; defaults to the phone gutter.
  final EdgeInsets? padding;

  /// Readable width cap for rows on wide windows.
  final double? maxWidth;

  /// Item shown in the iPad inspector, highlighted in the list.
  final String? selectedId;
}

/// Index view: compact rows, A–Z with letter headers.
List<Widget> indexSlivers(
  List<Item> items,
  ItemActions actions, {
  ListLayout layout = const ListLayout(),
}) => [
  for (final section in groupAlphabetically(items)) ...[
    _sectionHeader(SectionLabel(section.title), layout: layout),
    _rows(section.items, actions, layout: layout),
  ],
];

/// Locations view: items grouped under each place.
List<Widget> locationSlivers(
  List<Item> items,
  ItemActions actions, {
  ListLayout layout = const ListLayout(),
}) => [
  for (final section in groupByLocation(items)) ...[
    _sectionHeader(
      _LocationHeader(section.title, section.items.length),
      layout: layout,
    ),
    _rows(section.items, actions, showLocation: false, layout: layout),
  ],
];

/// Search results, already ranked by the search filter.
List<Widget> resultSlivers(
  List<Item> results,
  ItemActions actions, {
  ListLayout layout = const ListLayout(),
}) => [
  _sectionHeader(
    SectionLabel('Results', count: results.length),
    layout: layout,
  ),
  _rows(results, actions, layout: layout),
];

Widget _sectionHeader(
  Widget child, {
  ListLayout layout = const ListLayout(),
  EdgeInsets? padding,
}) {
  final side = padding ?? layout.padding ?? _pagePadding;
  return SliverPadding(
    padding: side.copyWith(top: 20.h, bottom: 10.h),
    sliver: _maybeConstrained(SliverToBoxAdapter(child: child), layout),
  );
}

Widget _maybeConstrained(Widget sliver, ListLayout layout) =>
    layout.maxWidth == null
    ? sliver
    : SliverConstrainedCrossAxis(maxExtent: layout.maxWidth!, sliver: sliver);

Widget _rows(
  List<Item> items,
  ItemActions actions, {
  bool showLocation = true,
  ListLayout layout = const ListLayout(),
}) => SliverPadding(
  padding: layout.padding ?? _pagePadding,
  sliver: _maybeConstrained(
    SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, i) {
        final item = items[i];
        return Dismissible(
          key: ValueKey('row-${item.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => actions.delete(item),
          background: const _DeleteBackground(),
          child: ItemCard(
            item: item,
            showLocation: showLocation,
            selected: item.id == layout.selectedId,
            onTap: () => actions.open(item),
            onDelete: () => actions.delete(item),
          ),
        );
      },
    ),
    layout,
  ),
);

class _LocationHeader extends StatelessWidget {
  const _LocationHeader(this.location, this.count);

  final String location;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      label: '$location, $count ${count == 1 ? 'item' : 'items'}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(Icons.place, size: 20.r, color: AppColors.orange),
          ),
          SizedBox(width: 6.w),
          Expanded(child: Text(location, style: theme.textTheme.titleLarge)),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppPalette.of(context).chip,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text('$count', style: theme.textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.w),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onError),
    );
  }
}
