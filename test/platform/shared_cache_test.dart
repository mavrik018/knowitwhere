import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/platform/shared_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// The JSON most recently written to the shared container.
  List<dynamic> lastSnapshot() {
    final save = calls.lastWhere((c) => c.method == 'saveWidgetData');
    return jsonDecode(save.arguments['data'] as String) as List<dynamic>;
  }

  test('encodes the flattened SRS §5 shape without photos', () {
    final item = Item(
      id: 'id-1',
      name: 'HDMI cable',
      location: 'Drawer 2',
      photoPath: 'photos/x.jpg',
      dateAdded: DateTime.utc(2026, 1, 1),
      dateUpdated: DateTime.utc(2026, 1, 2, 3, 4, 5),
    );

    expect(jsonDecode(encodeSharedCache([item])), [
      {
        'id': 'id-1',
        'name': 'HDMI cable',
        'location': 'Drawer 2',
        'updatedAt': '2026-01-02T03:04:05.000Z',
      },
    ]);
  });

  test('sink writes to the App Group then reloads the widget', () async {
    await const SharedCacheSink().onItemsChanged([]);

    expect(calls.map((c) => c.method), ['saveWidgetData', 'updateWidget']);
    expect(calls[0].arguments, {
      'id': sharedCacheKey,
      'data': '[]',
      'appGroupId': appGroupId,
    });
    expect(calls[1].arguments['ios'], widgetKind);
  });

  test('sink swallows platform errors', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: '-7');
    });

    await expectLater(const SharedCacheSink().onItemsChanged([]), completes);
  });

  test(
    'shared cache reflects every mutation immediately (Phase 3 exit)',
    () async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(db.close);
      final repo = ItemRepository(db, sink: const SharedCacheSink());

      final passport = await repo.add(name: 'Passport', location: 'Desk');
      expect(lastSnapshot(), [containsPair('location', 'Desk')]);

      await repo.update(passport.copyWith(location: 'Safe'));
      expect(lastSnapshot().single['location'], 'Safe');

      final keys = await repo.add(name: 'Keys', location: 'Hook');
      expect(lastSnapshot().map((e) => e['name']), ['Keys', 'Passport']);

      await repo.delete(keys.id);
      expect(lastSnapshot().map((e) => e['name']), ['Passport']);

      // One save + one widget reload per mutation, never batched.
      expect(calls.where((c) => c.method == 'saveWidgetData'), hasLength(4));
      expect(calls.where((c) => c.method == 'updateWidget'), hasLength(4));
    },
  );
}
