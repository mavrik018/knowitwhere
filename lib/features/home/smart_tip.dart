import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';

/// One helpful tip at the bottom of the home screen, changing daily.
class SmartTip extends StatelessWidget {
  const SmartTip({super.key, required this.day});

  /// Day index used to pick the tip (e.g. days since epoch).
  final int day;

  static const tips = [
    'Hands full? Ask Siri: “$siriPhraseShort”',
    'Add the KnowItWhere widget to your home screen to see where things are '
        'at a glance.',
    'Snap a photo of the spot. Future you will thank you.',
    'Moved something? Update it so Siri gives the right answer.',
    'Swipe down on your home screen and search. Your items show up in '
        'Spotlight too.',
  ];

  static const siriPhraseShort = 'Where’s my passport in KnowItWhere?';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: palette.tip,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16.r, color: palette.tipText),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'SMART TIP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.tipText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            tips[day % tips.length],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.35,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
