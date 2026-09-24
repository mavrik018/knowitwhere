import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_directory.dart';
import 'data/database.dart';
import 'data/item_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The database opens lazily on first query, keeping cold start fast (§7).
  final db = AppDatabase.open(appDataDirectory);
  runApp(WdipitApp(repository: ItemRepository(db)));
}
