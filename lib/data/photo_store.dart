import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Stores item photos under `<app data dir>/photos` (FR3).
///
/// Only paths relative to the app data directory are handed out, because the
/// iOS sandbox path can change between launches (FR3.2).
class PhotoStore {
  PhotoStore(this.baseDir);

  final Directory baseDir;

  static const folder = 'photos';

  /// FR3.3 target size per photo.
  static const maxBytes = 1024 * 1024;

  File resolve(String relativePath) => File(p.join(baseDir.path, relativePath));

  /// Copies the picked image at [sourcePath] into the store, shrinking it if
  /// it is over [maxBytes], and returns its relative path.
  Future<String> save(String sourcePath) async {
    var bytes = await File(sourcePath).readAsBytes();
    if (bytes.length > maxBytes) bytes = await compute(shrinkImage, bytes);
    final relativePath = '$folder/${const Uuid().v4()}.jpg';
    final file = resolve(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relativePath;
  }

  /// Deletes photo files that no item references: photos of deleted items,
  /// replaced photos, and picks from cancelled forms.
  ///
  /// Files modified within [minAge] are kept so a delete can still be undone
  /// and a photo saved just before its item row is never swept.
  Future<int> deleteOrphans(
    Set<String> referenced, {
    Duration minAge = const Duration(hours: 1),
  }) async {
    final dir = Directory(p.join(baseDir.path, folder));
    if (!await dir.exists()) return 0;
    final cutoff = DateTime.now().subtract(minAge);
    var deleted = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final relativePath = '$folder/${p.basename(entity.path)}';
      if (referenced.contains(relativePath)) continue;
      if ((await entity.lastModified()).isAfter(cutoff)) continue;
      await entity.delete();
      deleted++;
    }
    return deleted;
  }
}

/// Re-encodes [bytes] as a JPEG of at most [maxBytes], stepping down size and
/// quality until it fits. Returns [bytes] unchanged if they can't be decoded.
///
/// Runs in a background isolate via [compute].
Uint8List shrinkImage(Uint8List bytes, {int maxBytes = PhotoStore.maxBytes}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final image = img.bakeOrientation(decoded);

  Uint8List? out;
  for (final (side, quality) in const [
    (1600, 80),
    (1600, 65),
    (1200, 60),
    (900, 55),
    (700, 50),
  ]) {
    final resized = image.width >= image.height
        ? (image.width > side ? img.copyResize(image, width: side) : image)
        : (image.height > side ? img.copyResize(image, height: side) : image);
    out = img.encodeJpg(resized, quality: quality);
    if (out.length <= maxBytes) break;
  }
  return out!;
}
