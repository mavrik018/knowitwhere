import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_directory.dart';
import 'data/database.dart';
import 'data/item_repository.dart';
import 'data/photo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await appDataDirectory();
  // The database itself opens lazily on first query, keeping cold start fast.
  final db = AppDatabase.open(() async => dir);
  final repository = ItemRepository(db);
  final photos = PhotoStore(dir);

  runApp(WdipitApp(repository: repository, photos: photos));

  unawaited(_sweepOrphanPhotos(repository, photos));
}

Future<void> _sweepOrphanPhotos(ItemRepository repo, PhotoStore photos) async {
  try {
    final items = await repo.getAll();
    await photos.deleteOrphans(items.map((i) => i.photoPath).nonNulls.toSet());
  } catch (e) {
    debugPrint('Photo cleanup skipped: $e');
  }
}
