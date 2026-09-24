import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Directory holding the database and photos.
///
/// On iOS this is the Documents directory, which is included in device
/// backups (SRS §7). Other platforms are dev-only and use the app support
/// directory so they don't clutter the user's Documents folder.
Future<Directory> appDataDirectory() async {
  final dir = Platform.isIOS
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return dir;
}
