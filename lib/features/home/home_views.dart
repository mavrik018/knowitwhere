import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/database.dart';
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

/// Board view: two-column pinned-photo cards grouped by recency. Falls back
/// to one column at large text sizes so names stay readable.
List<Widget> boardSlivers(
  BuildContext context,
  List<Item> items,
  ItemActions actions,
) {
  final columns = MediaQuery.textScalerOf(context).scale(1) > 1.6 ? 1 : 2;
  return [
    for (final section in groupByRecency(items, DateTime.now())) ...[
      _sectionHeader(SectionLabel(section.title, count: section.items.length)),
      SliverPadding(
        padding: _pagePadding,
        sliver: SliverList.separated(
          itemCount: (section.items.length / columns).ceil(),
          separatorBuilder: (_, _) => SizedBox(height: 12.h),
          itemBuilder: (context, row) {
            final cells = section.items.skip(row * columns).take(columns);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in cells.indexed) ...[
                    if (i > 0) SizedBox(width: 12.w),
                    Expanded(
                      child: ItemBoardCard(
                        item: item,
                        onTap: () => actions.open(item),
                        onDelete: () => actions.delete(item),
                      ),
                    ),
                  ],
                  if (cells.length < columns) ...[
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

/// Index view: compact rows, A–Z with letter headers.
List<Widget> indexSlivers(List<Item> items, ItemActions actions) => [
  for (final section in groupAlphabetically(items)) ...[
    _sectionHeader(SectionLabel(section.title)),
    _rows(section.items, actions),
  ],
];

/// Locations view: items grouped under each place.
List<Widget> locationSlivers(List<Item> items, ItemActions actions) => [
  for (final section in groupByLocation(items)) ...[
    _sectionHeader(_LocationHeader(section.title, section.items.length)),
    _rows(section.items, actions, showLocation: false),
  ],
];

/// Search results, already ranked by the search filter.
List<Widget> resultSlivers(List<Item> results, ItemActions actions) => [
  _sectionHeader(SectionLabel('Results', count: results.length)),
  _rows(results, actions),
];

Widget _sectionHeader(Widget child) => SliverPadding(
  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
  sliver: SliverToBoxAdapter(child: child),
);

Widget _rows(
  List<Item> items,
  ItemActions actions, {
  bool showLocation = true,
}) => SliverPadding(
  padding: _pagePadding,
  sliver: SliverList.separated(
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
          onTap: () => actions.open(item),
          onDelete: () => actions.delete(item),
        ),
      );
    },
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
