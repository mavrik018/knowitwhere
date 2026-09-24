import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Example Siri phrase: the one-sentence App Shortcut (docs/siri-voice-ux.md).
const siriExamplePhrase = 'Hey Siri, where’s my passport in KnowItWhere?';

/// A dark "listening" pill with a mic icon and a quoted Siri phrase.
class SiriBar extends StatelessWidget {
  const SiriBar({super.key, this.phrase = siriExamplePhrase});

  final String phrase;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Try saying: $phrase',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.sage,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC6DACB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic_none_rounded, color: AppColors.sageInk),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '“$phrase”',
                style: const TextStyle(
                  color: AppColors.sageInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
