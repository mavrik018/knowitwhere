import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

/// Receives the full item list after every mutation (FR1.4).
///
/// Phase 3 plugs in the App Group shared-cache writer, widget reload and
/// Spotlight indexing here. It is awaited right after each DB write, never
/// batched (SRS §11).
abstract interface class ItemChangeSink {
  Future<void> onItemsChanged(List<Item> items);
}

class NoopItemChangeSink implements ItemChangeSink {
  const NoopItemChangeSink();

  @override
  Future<void> onItemsChanged(List<Item> items) async {}
}

class ItemRepository {
  ItemRepository(
    this._db, {
    this._sink = const NoopItemChangeSink(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final ItemChangeSink _sink;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  SimpleSelectStatement<$ItemsTable, Item> _allByRecency() =>
      _db.select(_db.items)..orderBy([(t) => OrderingTerm.desc(t.dateUpdated)]);

  /// All items, most recently updated first.
  Stream<List<Item>> watchAll() => _allByRecency().watch();

  Future<List<Item>> getAll() => _allByRecency().get();

  Stream<Item?> watch(String id) => (_db.select(
    _db.items,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Item?> get(String id) =>
      (_db.select(_db.items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Item> add({
    required String name,
    required String location,
    String? photoPath,
  }) async {
    final now = _clock();
    final item = Item(
      id: _uuid.v4(),
      name: name.trim(),
      location: location.trim(),
      photoPath: photoPath,
      dateAdded: now,
      dateUpdated: now,
    );
    await _db.into(_db.items).insert(item);
    await _notify();
    return item;
  }

  /// Saves [item]'s editable fields and bumps `dateUpdated` (FR1.2).
  Future<Item> update(Item item) async {
    final updated = item.copyWith(
      name: item.name.trim(),
      location: item.location.trim(),
      dateUpdated: _clock(),
    );
    await _db.update(_db.items).replace(updated);
    await _notify();
    return updated;
  }

  /// Deletes the row. The photo file is left for [PhotoStore.deleteOrphans]
  /// so that [restore] (swipe-to-delete undo) can bring the item back intact.
  Future<void> delete(String id) async {
    await (_db.delete(_db.items)..where((t) => t.id.equals(id))).go();
    await _notify();
  }

  /// Re-inserts a previously deleted item unchanged.
  Future<void> restore(Item item) async {
    await _db.into(_db.items).insertOnConflictUpdate(item);
    await _notify();
  }

  Future<void> _notify() async => _sink.onItemsChanged(await getAll());
}
