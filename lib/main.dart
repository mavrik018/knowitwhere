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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await appDataDirectory();
  // The database itself opens lazily on first query, keeping cold start fast.
  final db = AppDatabase.open(() async => dir);
  // The App Group bridge only exists on iOS; other platforms are dev-only.
  final repository = ItemRepository(
    db,
    sink: Platform.isIOS ? const SharedCacheSink() : const NoopItemChangeSink(),
  );
  final photos = PhotoStore(dir);

  runApp(
    KnowItWhereApp(
      repository: repository,
      photos: photos,
      deepLinks: Platform.isIOS ? AppLinks().uriLinkStream : null,
    ),
  );

  unawaited(_startupMaintenance(repository, photos));
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
