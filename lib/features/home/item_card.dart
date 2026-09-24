import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/semantics.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pinned_photo.dart';

/// Board view card: pinned photo, name, location.
class ItemBoardCard extends StatelessWidget {
  const ItemBoardCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
  });

  final Item item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ItemSemantics(
      item: item,
      onTap: onTap,
      onDelete: onDelete,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: _cardShadow(theme),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22.r),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PinnedPhoto(
                    item: item,
                    aspectRatio: 1.25,
                    radius: 16,
                    heroTag: 'photo-${item.id}',
                    cacheWidth: (220 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        _LocationLine(item.location),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact row for the Index, Locations and search views.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.showLocation = true,
  });

  final Item item;
  final VoidCallback onTap;

  /// Offered to VoiceOver as a custom action, mirroring swipe-to-delete.
  final VoidCallback? onDelete;

  /// Off in the Locations view, where the group header already says it.
  final bool showLocation;

  static const deleteAction = CustomSemanticsAction(label: 'Delete');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ItemSemantics(
      item: item,
      onTap: onTap,
      onDelete: onDelete,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: _cardShadow(theme),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18.r),
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Row(
                children: [
                  SizedBox(
                    width: 48.r,
                    child: PinnedPhoto(
                      item: item,
                      radius: 12,
                      heroTag: 'photo-${item.id}',
                      cacheWidth: (48 * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: theme.textTheme.titleMedium),
                        if (showLocation) ...[
                          SizedBox(height: 2.h),
                          _LocationLine(item.location, maxLines: 2),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 22.r,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _cardShadow(ThemeData theme) =>
    theme.brightness == Brightness.dark
    ? const []
    : const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ];

class _LocationLine extends StatelessWidget {
  const _LocationLine(this.location, {this.maxLines = 1});

  final String location;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Icon(
            Icons.place_outlined,
            size: 15.r,
            color: AppColors.orange,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            location,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// One VoiceOver element per item: "{name}, stored in {location}", with tap
/// to open and a Delete custom action.
class _ItemSemantics extends StatelessWidget {
  const _ItemSemantics({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.child,
  });

  final Item item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onDelete = this.onDelete;
    return Semantics(
      button: true,
      label: '${item.name}, stored in ${item.location}',
      // The children are excluded, so the tap must be re-exposed here.
      onTap: onTap,
      customSemanticsActions: onDelete == null
          ? null
          : {ItemCard.deleteAction: onDelete},
      excludeSemantics: true,
      child: child,
    );
  }
}
