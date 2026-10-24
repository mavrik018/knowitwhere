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

/// Fans a change out to several sinks, in order.
class CompositeItemChangeSink implements ItemChangeSink {
  const CompositeItemChangeSink(this.sinks);

  final List<ItemChangeSink> sinks;

  @override
  Future<void> onItemsChanged(List<Item> items) async {
    for (final sink in sinks) {
      await sink.onItemsChanged(items);
    }
  }
}

/// The form of a name used to spot duplicates: "  Passport " and
/// "passport" are the same item.
String normalizeName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
    await publishSnapshot();
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
    await publishSnapshot();
    return updated;
  }

  /// Deletes the row. The photo file is left for [PhotoStore.deleteOrphans]
  /// so that [restore] (swipe-to-delete undo) can bring the item back intact.
  Future<void> delete(String id) async {
    await (_db.delete(_db.items)..where((t) => t.id.equals(id))).go();
    await publishSnapshot();
  }

  /// Re-inserts a previously deleted item unchanged.
  ///
  /// Returns false, and restores nothing, if another item with the same name
  /// was saved in the meantime: names are unique so Siri's answer is too.
  Future<bool> restore(Item item) async {
    if (await findByName(item.name, exceptId: item.id) != null) return false;
    await _db.into(_db.items).insertOnConflictUpdate(item);
    await publishSnapshot();
    return true;
  }

  /// The item called [name], ignoring case and extra spaces, other than
  /// [exceptId] (the item being edited). Used to keep names unique.
  Future<Item?> findByName(String name, {String? exceptId}) async {
    final wanted = normalizeName(name);
    for (final item in await getAll()) {
      if (item.id != exceptId && normalizeName(item.name) == wanted) {
        return item;
      }
    }
    return null;
  }

  /// Pushes the current full list to the sink, e.g. at launch so the shared
  /// cache is rebuilt after a backup restore.
  Future<void> publishSnapshot() async => _sink.onItemsChanged(await getAll());
}
