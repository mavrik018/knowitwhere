import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/item_photo.dart';
import '../../widgets/pinned_photo.dart';

/// Board view card: authentic Polaroid with photo, handwritten title, location, and thumbpin.
class ItemBoardCard extends StatelessWidget {
  const ItemBoardCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.tiltAngle = 0.0,
  });

  final Item item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final double tiltAngle;

  static const _handwrittenFonts = [
    'Noteworthy',
    'Marker Felt',
    'Chalkboard SE',
    'Bradley Hand',
    'Segoe Print',
    'Ink Free',
    'Caveat',
    'cursive',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photoPath = item.photoPath;
    final palette = AppPalette.of(context);

    final photoWidget = photoPath == null
        ? ColoredBox(
            color: palette.photoPlaceholder,
            child: const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: AppColors.orange,
              ),
            ),
          )
        : ItemPhoto(
            file: AppScope.of(context).photos.resolve(photoPath),
            cacheWidth: (220 * MediaQuery.devicePixelRatioOf(context)).round(),
            semanticLabel: 'Photo of ${item.name}',
          );

    return _ItemSemantics(
      item: item,
      onTap: onTap,
      onDelete: onDelete,
      child: Transform.rotate(
        angle: tiltAngle,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Polaroid card container
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2723) : const Color(0xFFFAF7EE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
                    width: 0.8,
                  ),
                  boxShadow: _polaroidShadow(theme),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(9, 9, 9, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Photo container with thin polaroid inset
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Hero(
                                tag: 'photo-${item.id}',
                                child: photoWidget,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Polaroid bottom chin: handwritten note area
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamilyFallback: _handwrittenFonts,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFF1ECE4)
                                        : const Color(0xFF2E2925),
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.location,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamilyFallback: _handwrittenFonts,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFFB7AFA5)
                                        : const Color(0xFF6B655D),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Thumbpin at top center of the Polaroid
              const Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: PinDot(size: 28),
                ),
              ),
            ],
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

List<BoxShadow> _polaroidShadow(ThemeData theme) =>
    theme.brightness == Brightness.dark
    ? const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ]
    : const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x0C000000),
          blurRadius: 3,
          spreadRadius: 0,
          offset: Offset(0, 1),
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
