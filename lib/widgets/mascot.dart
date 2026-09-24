import 'package:flutter/material.dart';

/// The knowitwhere squirrel.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.height, this.semanticLabel});

  static const asset = 'assets/images/mascot.png';

  final double? height;

  /// Null makes the image decorative (hidden from VoiceOver).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
