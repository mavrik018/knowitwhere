import 'package:flutter/widgets.dart';

import 'data/item_repository.dart';

/// Makes app-wide services available to screens.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.repository, required super.child});

  final ItemRepository repository;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repository != oldWidget.repository;
}
