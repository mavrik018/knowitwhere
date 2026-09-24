import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/platform/spotlight.dart';

Item _item(String id, String name, String location) => Item(
  id: id,
  name: name,
  location: location,
  photoPath: 'photos/$id.jpg',
  dateAdded: DateTime(2026),
  dateUpdated: DateTime(2026),
);

class _RecordingSink implements ItemChangeSink {
  _RecordingSink(this.name, this.log);

  final String name;
  final List<String> log;

  @override
  Future<void> onItemsChanged(List<Item> items) async => log.add(name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  String? initialItem;

  setUp(() {
    calls = [];
    initialItem = null;
    messenger.setMockMethodCallHandler(spotlightChannel, (call) async {
      calls.add(call);
      return call.method == 'takeInitialItem' ? initialItem : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(spotlightChannel, null));

  test('sink replaces the index with id, name and location only', () async {
    await const SpotlightSink().onItemsChanged([
      _item('1', 'Passport', 'Desk'),
      _item('2', 'Keys', 'Hook'),
    ]);

    expect(calls.single.method, 'replaceAll');
    expect(calls.single.arguments, [
      {'id': '1', 'name': 'Passport', 'location': 'Desk'},
      {'id': '2', 'name': 'Keys', 'location': 'Hook'},
    ]);
  });

  test('an empty list clears the index', () async {
    await const SpotlightSink().onItemsChanged([]);
    expect(calls.single.arguments, isEmpty);
  });

  test('sink swallows platform errors', () async {
    messenger.setMockMethodCallHandler(spotlightChannel, (call) async {
      throw PlatformException(code: 'spotlight_failed');
    });
    await expectLater(const SpotlightSink().onItemsChanged([]), completes);
  });

  test('taps become item deep links, including the launch tap', () async {
    initialItem = 'launch-id';
    final links = <Uri>[];
    final sub = spotlightTaps().listen(links.add);
    await pumpEventQueue();

    // Native side reports a later tap.
    await messenger.handlePlatformMessage(
      spotlightChannel.name,
      spotlightChannel.codec.encodeMethodCall(
        const MethodCall('openItem', 'later-id'),
      ),
      (_) {},
    );
    await pumpEventQueue();

    expect(links.map((u) => u.toString()), [
      'knowitwhere://item/launch-id',
      'knowitwhere://item/later-id',
    ]);
    await sub.cancel();
  });

  test('composite sink calls every sink in order', () async {
    final log = <String>[];
    await CompositeItemChangeSink([
      _RecordingSink('cache', log),
      _RecordingSink('spotlight', log),
    ]).onItemsChanged([]);

    expect(log, ['cache', 'spotlight']);
  });
}
