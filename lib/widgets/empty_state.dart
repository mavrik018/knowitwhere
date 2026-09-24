import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    required this.message,
    this.action,
  }) : assert(icon != null || illustration != null);

  final IconData? icon;

  /// Shown instead of [icon], e.g. the mascot.
  final Widget? illustration;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration ??
              Icon(icon, size: 48.r, color: theme.colorScheme.primary),
          SizedBox(height: 14.h),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[SizedBox(height: 18.h), action!],
        ],
      ),
    );
  }
}
