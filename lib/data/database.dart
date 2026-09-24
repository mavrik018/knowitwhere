import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Source-of-truth item table (SRS §5).
@DataClassName('Item')
class Items extends Table {
  /// UUID v4.
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get location => text()();

  /// Path relative to the app data directory, never absolute (FR3.2).
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-disk database `knowitwhere.sqlite` inside [directory].
  factory AppDatabase.open(Future<Object> Function() directory) => AppDatabase(
    driftDatabase(
      name: 'knowitwhere',
      native: DriftNativeOptions(databaseDirectory: directory),
    ),
  );

  @override
  int get schemaVersion => 1;
}
