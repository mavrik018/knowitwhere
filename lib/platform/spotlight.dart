import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/item_repository.dart';
import 'deep_links.dart';

/// Implemented natively by `ios/Runner/SpotlightPlugin.swift`.
const spotlightChannel = MethodChannel('knowitwhere/spotlight');

/// Re-indexes every item in Core Spotlight after each mutation (FR1.4 d,
/// FR7.1): name as title, location as description. Replacing the whole set
/// also de-indexes deleted items.
class SpotlightSink implements ItemChangeSink {
  const SpotlightSink();

  @override
  Future<void> onItemsChanged(List<Item> items) async {
    try {
      await spotlightChannel.invokeMethod<void>('replaceAll', [
        for (final item in items)
          {'id': item.id, 'name': item.name, 'location': item.location},
      ]);
    } catch (e) {
      debugPrint('Spotlight indexing failed: $e');
    }
  }
}

/// Spotlight result taps as `knowitwhere://item/{id}` links (FR7.2),
/// including the tap that launched the app.
Stream<Uri> spotlightTaps() {
  late final StreamController<Uri> controller;
  Uri link(String id) =>
      Uri(scheme: urlScheme, host: 'item', pathSegments: [id]);

  controller = StreamController<Uri>(
    onListen: () async {
      spotlightChannel.setMethodCallHandler((call) async {
        if (call.method == 'openItem' && call.arguments is String) {
          controller.add(link(call.arguments as String));
        }
      });
      try {
        final initial = await spotlightChannel.invokeMethod<String>(
          'takeInitialItem',
        );
        if (initial != null) controller.add(link(initial));
      } catch (e) {
        debugPrint('Spotlight initial item unavailable: $e');
      }
    },
    onCancel: () => spotlightChannel.setMethodCallHandler(null),
  );
  return controller.stream;
}
