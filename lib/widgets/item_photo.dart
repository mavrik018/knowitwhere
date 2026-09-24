import 'dart:io';

import 'package:flutter/material.dart';

/// A cover-fit item photo that degrades to a placeholder if the file is gone.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.file,
    this.cacheWidth,
    this.semanticLabel,
  });

  final File file;

  /// Decode width in physical pixels; set for thumbnails to save memory.
  final int? cacheWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
