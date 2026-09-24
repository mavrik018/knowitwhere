import 'package:flutter/material.dart';
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
          borderRadius: BorderRadius.circular(26),
          boxShadow: _cardShadow(theme),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PinnedPhoto(
                    item: item,
                    aspectRatio: 1.05,
                    heroTag: 'photo-${item.id}',
                    cacheWidth: (220 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: _cardShadow(theme),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: PinnedPhoto(
                      item: item,
                      radius: 14,
                      heroTag: 'photo-${item.id}',
                      cacheWidth: (56 * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: theme.textTheme.titleMedium),
                        if (showLocation) ...[
                          const SizedBox(height: 3),
                          _LocationLine(item.location, maxLines: 2),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
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
          blurRadius: 18,
          offset: Offset(0, 6),
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
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.place_outlined, size: 17, color: AppColors.orange),
        ),
        const SizedBox(width: 4),
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
