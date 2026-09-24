import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Example Siri phrase: the one-sentence App Shortcut (docs/siri-voice-ux.md).
const siriExamplePhrase = 'Hey Siri, where’s my passport in knowitwhere?';

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
          color: AppColors.nightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3A342E)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic_none_rounded, color: AppColors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '“$phrase”',
                style: const TextStyle(
                  color: Color(0xFFF1ECE4),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
