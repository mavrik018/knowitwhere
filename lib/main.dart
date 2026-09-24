import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_directory.dart';
import 'data/database.dart';
import 'data/item_repository.dart';
import 'data/photo_store.dart';
import 'platform/shared_cache.dart';
import 'platform/spotlight.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await appDataDirectory();
  // The database itself opens lazily on first query, keeping cold start fast.
  final db = AppDatabase.open(() async => dir);
  // Native surfaces only exist on iOS; other platforms are dev-only.
  final repository = ItemRepository(
    db,
    sink: Platform.isIOS
        ? const CompositeItemChangeSink([SharedCacheSink(), SpotlightSink()])
        : const NoopItemChangeSink(),
  );
  final photos = PhotoStore(dir);

  runApp(
    KnowItWhereApp(
      repository: repository,
      photos: photos,
      deepLinks: Platform.isIOS
          ? _merge([AppLinks().uriLinkStream, spotlightTaps()])
          : null,
    ),
  );

  unawaited(_startupMaintenance(repository, photos));
}

Stream<T> _merge<T>(List<Stream<T>> streams) {
  final subs = <StreamSubscription<T>>[];
  late final StreamController<T> controller;
  controller = StreamController<T>(
    onListen: () {
      for (final s in streams) {
        subs.add(s.listen(controller.add, onError: controller.addError));
      }
    },
    onCancel: () => Future.wait(subs.map((s) => s.cancel())),
  );
  return controller.stream;
}

Future<void> _startupMaintenance(ItemRepository repo, PhotoStore photos) async {
  try {
    // Rebuild the shared cache in case it is missing, e.g. after a restore.
    await repo.publishSnapshot();
    final items = await repo.getAll();
    await photos.deleteOrphans(items.map((i) => i.photoPath).nonNulls.toSet());
  } catch (e) {
    debugPrint('Startup maintenance skipped: $e');
  }
}
