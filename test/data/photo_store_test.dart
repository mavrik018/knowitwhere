import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:discoverly/data/photo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory tmp;
  late PhotoStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('photo_store_test');
    store = PhotoStore(tmp);
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<File> writeSource(String name, List<int> bytes) =>
      File('${tmp.path}/$name').writeAsBytes(bytes);

  /// Random noise compresses badly, so this PNG is well over 1 MB.
  Uint8List noisyPng(int width, int height) {
    final rnd = Random(1);
    final image = img.Image(width: width, height: height);
    for (final p in image) {
      p
        ..r = rnd.nextInt(256)
        ..g = rnd.nextInt(256)
        ..b = rnd.nextInt(256);
    }
    return img.encodePng(image);
  }

  test(
    'save returns a relative path that resolves to the copied file',
    () async {
      final source = await writeSource('small.jpg', [1, 2, 3, 4]);

      final relative = await store.save(source.path);

      expect(relative, startsWith('photos/'));
      expect(relative, endsWith('.jpg'));
      expect(File(relative).isAbsolute, isFalse);
      expect(await store.resolve(relative).readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test('save shrinks photos over 1 MB', () async {
    final big = noisyPng(2000, 1500);
    expect(big.length, greaterThan(PhotoStore.maxBytes));
    final source = await writeSource('big.png', big);

    final relative = await store.save(source.path);
    final saved = await store.resolve(relative).readAsBytes();

    expect(saved.length, lessThanOrEqualTo(PhotoStore.maxBytes));
    final decoded = img.decodeJpg(saved)!;
    expect(max(decoded.width, decoded.height), lessThanOrEqualTo(1600));
  });

  test('shrinkImage leaves undecodable bytes untouched', () {
    final junk = Uint8List.fromList(List.filled(2000, 7));
    expect(shrinkImage(junk, maxBytes: 10), same(junk));
  });

  test('deleteOrphans removes only old, unreferenced photos', () async {
    final keep = await store.save((await writeSource('a', [1])).path);
    final orphan = await store.save((await writeSource('b', [2])).path);
    final fresh = await store.save((await writeSource('c', [3])).path);
    final old = DateTime.now().subtract(const Duration(days: 1));
    await store.resolve(keep).setLastModified(old);
    await store.resolve(orphan).setLastModified(old);

    final deleted = await store.deleteOrphans({keep});

    expect(deleted, 1);
    expect(await store.resolve(keep).exists(), isTrue);
    expect(await store.resolve(orphan).exists(), isFalse);
    expect(await store.resolve(fresh).exists(), isTrue);
  });

  test('deleteOrphans is a no-op before any photo is saved', () async {
    expect(await store.deleteOrphans({}), 0);
  });
}
