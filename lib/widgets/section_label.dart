import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          padding: EdgeInsets.only(top: 8.h),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Manila craft paper tag
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF38322B)
                      : const Color(0xFFFDEEE3),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0xFFF2D9C8),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark
                          ? const Color(0xFFF1ECE4)
                          : const Color(0xFF5D4638),
                    ),
                  ),
                ),
              ),
              // Frosted semi-transparent tape at the top center
              Positioned(
                top: -7.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 44.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x44FFFFFF)
                          : const Color(0x88FCE0CC),
                      borderRadius: BorderRadius.circular(2.r),
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
        fontSize: 13.sp,
      ),
    );
  }
}
