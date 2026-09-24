import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Upper-case section chip rendered as a taped manila paper label, e.g. "RECENT (THIS WEEK) · 2".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = count == null ? text : '$text · $count';

    return Semantics(
      header: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Manila craft paper tag
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF38322B)
                      : const Color(0xFFEDE3D0),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0x1F000000),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamilyFallback: const [
                        'Courier New',
                        'Courier',
                        'Menlo',
                        'monospace',
                      ],
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: isDark
                          ? const Color(0xFFE2D8CA)
                          : const Color(0xFF52483C),
                    ),
                  ),
                ),
              ),
              // Frosted semi-transparent tape at the top center
              Positioned(
                top: -7,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x44FFFFFF)
                          : const Color(0x88E8DECD),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: const Color(0x33FFFFFF),
                        width: 0.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small orange upper-case line above a headline.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: AppPalette.of(context).accentText,
        fontSize: 13.5,
      ),
    );
  }
}
