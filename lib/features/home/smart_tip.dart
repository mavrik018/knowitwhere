import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: palette.tip,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: palette.tipText),
              const SizedBox(width: 6),
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
          const SizedBox(height: 8),
          Text(
            tips[day % tips.length],
            style: theme.textTheme.bodyLarge?.copyWith(
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
