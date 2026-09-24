import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../theme/app_theme.dart';
import 'item_photo.dart';

/// An item's photo "pinned" to the card with an orange dot, or a soft
/// placeholder when there is no photo. [radius] is in design units and is
/// scaled with ScreenUtil.
class PinnedPhoto extends StatelessWidget {
  const PinnedPhoto({
    super.key,
    required this.item,
    this.aspectRatio = 1,
    this.radius = 18,
    this.cacheWidth,
    this.semanticLabel,
    this.heroTag,
  });

  final Item item;
  final double aspectRatio;
  final double radius;
  final int? cacheWidth;
  final String? semanticLabel;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final photoPath = item.photoPath;
    Widget photo = photoPath == null
        ? ColoredBox(
            color: palette.photoPlaceholder,
            child: Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 30.r,
                color: AppColors.orange,
              ),
            ),
          )
        : ItemPhoto(
            file: AppScope.of(context).photos.resolve(photoPath),
            cacheWidth: cacheWidth,
            semanticLabel: semanticLabel,
          );
    if (heroTag != null) photo = Hero(tag: heroTag!, child: photo);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius.r),
          child: AspectRatio(aspectRatio: aspectRatio, child: photo),
        ),
        Positioned(
          top: -5.r,
          left: 0,
          right: 0,
          child: const Center(child: PinDot()),
        ),
      ],
    );
  }
}

class PinDot extends StatelessWidget {
  const PinDot({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    final size = this.size.r;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: size * 0.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
