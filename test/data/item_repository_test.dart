import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingSink implements ItemChangeSink {
  final calls = <List<Item>>[];

  @override
  Future<void> onItemsChanged(List<Item> items) async => calls.add(items);
}

void main() {
  late AppDatabase db;
  late RecordingSink sink;
  late ItemRepository repo;
  late DateTime now;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    sink = RecordingSink();
    now = DateTime(2026, 1, 1, 12);
    repo = ItemRepository(db, sink: sink, clock: () => now);
  });

  tearDown(() => db.close());

  test('add stores a trimmed item with matching timestamps', () async {
    final item = await repo.add(name: ' Passport ', location: ' Desk drawer ');

    expect(item.id, hasLength(36));
    expect(item.name, 'Passport');
    expect(item.location, 'Desk drawer');
    expect(item.photoPath, isNull);
    expect(item.dateAdded, now);
    expect(item.dateUpdated, now);
    expect(await repo.get(item.id), item);
  });

  test('update bumps dateUpdated but keeps dateAdded', () async {
    final item = await repo.add(name: 'HDMI cable', location: 'Drawer 2');
    now = now.add(const Duration(hours: 1));

    final updated = await repo.update(item.copyWith(location: 'Drawer 3'));

    expect(updated.location, 'Drawer 3');
    expect(updated.dateAdded, item.dateAdded);
    expect(updated.dateUpdated, now);
    expect(await repo.get(item.id), updated);
  });

  test('getAll orders by most recently updated', () async {
    final a = await repo.add(name: 'A', location: 'x');
    now = now.add(const Duration(minutes: 1));
    await repo.add(name: 'B', location: 'x');
    now = now.add(const Duration(minutes: 1));
    await repo.update(a);

    expect((await repo.getAll()).map((i) => i.name), ['A', 'B']);
  });

  test('recency ordering keeps sub-second precision', () async {
    await repo.add(name: 'First', location: 'x');
    now = now.add(const Duration(milliseconds: 5));
    await repo.add(name: 'Second', location: 'x');

    expect((await repo.getAll()).map((i) => i.name), ['Second', 'First']);
  });

  test('delete removes the item and restore brings it back', () async {
    final item = await repo.add(
      name: 'Keys',
      location: 'Hook',
      photoPath: 'photos/k.jpg',
    );

    await repo.delete(item.id);
    expect(await repo.get(item.id), isNull);

    expect(await repo.restore(item), isTrue);
    expect(await repo.get(item.id), item);
  });

  test(
    'findByName ignores case and spacing, and the item being edited',
    () async {
      final item = await repo.add(name: 'HDMI cable', location: 'TV');

      expect((await repo.findByName('  hdmi   CABLE '))?.id, item.id);
      expect(await repo.findByName('HDMI cable', exceptId: item.id), isNull);
      expect(await repo.findByName('HDMI'), isNull);
    },
  );

  test('restore refuses a name that was saved again meanwhile', () async {
    final item = await repo.add(name: 'Passport', location: 'Desk');
    await repo.delete(item.id);
    await repo.add(name: 'passport', location: 'Safe');

    expect(await repo.restore(item), isFalse);
    expect((await repo.getAll()).map((i) => i.location), ['Safe']);
  });

  test('every mutation notifies the sink with the full list', () async {
    final item = await repo.add(name: 'Keys', location: 'Hook');
    await repo.update(item.copyWith(location: 'Bowl'));
    await repo.delete(item.id);
    await repo.restore(item);

    expect(sink.calls, hasLength(4));
    expect(sink.calls[0].single.location, 'Hook');
    expect(sink.calls[1].single.location, 'Bowl');
    expect(sink.calls[2], isEmpty);
    expect(sink.calls[3].single.id, item.id);
  });

  test('watchAll emits on change', () async {
    final emissions = repo.watchAll().map((l) => l.length);
    final expectation = expectLater(emissions, emitsInOrder([0, 1]));
    await pumpEventQueue();
    await repo.add(name: 'Keys', location: 'Hook');
    await expectation;
  });
}
