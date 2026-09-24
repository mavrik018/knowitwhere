import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../data/database.dart';
import '../data/item_repository.dart';

/// App Group shared by the app, the widget and the Siri extension (SRS §4.2).
const appGroupId = 'group.com.AandMapps.knowitwhere';

/// UserDefaults key (in the [appGroupId] suite) holding the JSON snapshot.
const sharedCacheKey = 'items';

/// WidgetKit `kind` of the home-screen widget (Phase 4).
const widgetKind = 'KnowItWhereWidget';

/// The flattened snapshot the native extensions read (SRS §5):
/// `[{"id", "name", "location", "updatedAt"}]`, most recently updated first,
/// with `updatedAt` as UTC ISO 8601. No photos.
String encodeSharedCache(List<Item> items) => jsonEncode([
  for (final item in items)
    {
      'id': item.id,
      'name': item.name,
      'location': item.location,
      'updatedAt': item.dateUpdated.toUtc().toIso8601String(),
    },
]);

/// Writes the snapshot into the App Group container and reloads the widget
/// after every mutation (FR1.4 b+c, SRS §4.4).
///
/// Failures are logged rather than thrown: the DB write has already succeeded
/// and the next mutation or launch rewrites the whole snapshot anyway.
class SharedCacheSink implements ItemChangeSink {
  const SharedCacheSink();

  @override
  Future<void> onItemsChanged(List<Item> items) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        sharedCacheKey,
        encodeSharedCache(items),
        appGroupId: appGroupId,
      );
      await HomeWidget.updateWidget(iOSName: widgetKind);
      if (kDebugMode) {
        debugPrint('Shared cache: wrote ${items.length} item(s)');
      }
    } catch (e) {
      debugPrint('Shared cache write failed: $e');
    }
  }
}
