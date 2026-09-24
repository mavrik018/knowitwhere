import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Upper-case section chip, e.g. "RECENT (THIS WEEK) · 2".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count == null ? text : '$text · $count';
    return Semantics(
      header: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppPalette.of(context).chip,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
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
