import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/item_repository.dart';

/// Implemented natively in `ios/Runner/KnowItWhereShortcuts.swift`.
const siriChannel = MethodChannel('knowitwhere/siri');

/// Tells Siri to re-read the item names it listens for after each mutation,
/// so "Where's my {item} in KnowItWhere?" works for an item added a moment
/// ago (FR5). Siri reads the names from the App Group cache, so this must run
/// after [SharedCacheSink].
class SiriSink implements ItemChangeSink {
  const SiriSink();

  @override
  Future<void> onItemsChanged(List<Item> items) async {
    try {
      await siriChannel.invokeMethod<void>('refresh');
    } catch (e) {
      debugPrint('Siri refresh failed: $e');
    }
  }
}
