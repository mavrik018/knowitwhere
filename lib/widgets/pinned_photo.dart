import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../theme/app_theme.dart';
import 'item_photo.dart';

/// An item's photo "pinned" to the card with a thumbpin, or a soft
/// placeholder when there is no photo. [radius] and [pinSize] are in design
/// units and are scaled with ScreenUtil.
class PinnedPhoto extends StatelessWidget {
  const PinnedPhoto({
    super.key,
    required this.item,
    this.aspectRatio = 1,
    this.radius = 18,
    this.pinSize,
    this.cacheWidth,
    this.semanticLabel,
    this.heroTag,
    this.showPin = true,
  });

  final Item item;
  final double aspectRatio;
  final double radius;
  final double? pinSize;
  final int? cacheWidth;
  final String? semanticLabel;
  final Object? heroTag;
  final bool showPin;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final photoPath = item.photoPath;
    final effectivePinSize = pinSize ?? (radius <= 14 ? 18.0 : 28.0);
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
        if (showPin)
          Positioned(
            top: -effectivePinSize.r * 0.42,
            left: 0,
            right: 0,
            child: Center(child: PinDot(size: effectivePinSize)),
          ),
      ],
    );
  }
}

class PinDot extends StatelessWidget {
  const PinDot({super.key, this.size = 28});

  static const asset = 'assets/images/thumbpin.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    final size = this.size.r;
    return ExcludeSemantics(
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
