import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/platform/siri.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(siriChannel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(siriChannel, null));

  test('sink asks Siri to refresh item names', () async {
    await const SiriSink().onItemsChanged([]);
    expect(calls.single.method, 'refresh');
  });

  test('sink swallows platform errors', () async {
    messenger.setMockMethodCallHandler(siriChannel, (call) async {
      throw PlatformException(code: 'failed');
    });
    await expectLater(const SiriSink().onItemsChanged([]), completes);
  });
}
