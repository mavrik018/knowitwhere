import 'package:flutter/widgets.dart';

import 'data/item_repository.dart';
import 'data/photo_store.dart';

/// Makes app-wide services available to screens.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.photos,
    required super.child,
  });

  final ItemRepository repository;
  final PhotoStore photos;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repository != oldWidget.repository || photos != oldWidget.photos;
}
