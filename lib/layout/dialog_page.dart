import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'window_size.dart';

/// A go_router page shown as a centred modal card over a dimmed backdrop,
/// used for Add/Edit on iPad instead of a full-screen push. Escape, the
/// close button and tapping outside all dismiss it.
class DialogPage<T> extends Page<T> {
  const DialogPage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
    context: context,
    settings: this,
    barrierDismissible: true,
    barrierColor: Colors.black38,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: TabletMetrics.dialogMaxWidth,
              maxHeight: math.min(620, size.height - 48),
            ),
            child: Material(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(24),
              elevation: 12,
              // Take keyboard focus, and bind Escape here: the form's own
              // Scaffold claims DismissIntent (for drawers) and would swallow
              // it before the dialog route could close.
              child: FocusScope(
                autofocus: true,
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): () =>
                        Navigator.maybePop(context),
                  },
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Full-screen page on phones, centred modal card on wide windows.
Page<void> adaptivePage(BuildContext context, LocalKey key, Widget child) {
  if (WindowSize.of(context).isWide) {
    return DialogPage<void>(key: key, child: child);
  }
  return MaterialPage<void>(key: key, child: child);
}

/// True when the current route is one of the modal cards above.
bool isInDialog(BuildContext context) => ModalRoute.of(context) is DialogRoute;
