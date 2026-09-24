// Renders the main screens to PNGs with real fonts, for design review.
//
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
//
// Output: docs/screens/*.png. Uses Roboto from the Flutter SDK, so text is
// close to, but not identical to, SF Pro on iOS.
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/app.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/data/photo_store.dart';

final _sdkFonts =
    '${Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter'}'
    '/bin/cache/artifacts/material_fonts';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('$_sdkFonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late Directory tmp;
  late PhotoStore photos;
  var clock = DateTime.now();

  setUpAll(() async {
    await _loadFont('Roboto', [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf',
    ]);
    await _loadFont('MaterialIcons', ['materialicons-regular.otf']);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('screens');
    photos = PhotoStore(tmp);
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    clock = DateTime.now();
    repo = ItemRepository(db, clock: () => clock);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<void> seed(WidgetTester tester) async {
    // Real file IO needs runAsync; the database writes must stay outside it.
    final mascotPhoto = await tester.runAsync(
      () => photos.save('tool/screenshots/sample_photo.jpg'),
    );
    Future<void> add(String name, String location, int daysAgo, [String? p]) {
      clock = DateTime.now().subtract(Duration(days: daysAgo, minutes: 1));
      return repo.add(name: name, location: location, photoPath: p);
    }

    await add('Tent', 'Loft, left side', 40);
    await add('Warranty papers', 'Blue folder', 25);
    await add('Winter Down Jacket', 'Hall closet · Top bin', 12);
    await add('140W USB-C Charger', 'Tech pouch · Front pocket', 10);
    await add('Spare Keys', 'Entry console · Ceramic bowl', 2, mascotPhoto);
    await add('Passport & Pouch', 'Bedside table · Top drawer', 0);
    clock = DateTime.now();
  }

  Future<void> pump(WidgetTester tester, {bool onboarding = false}) async {
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      KnowItWhereApp(
        repository: repo,
        photos: photos,
        showOnboarding: onboarding,
      ),
    );
    await tester.pumpAndSettle();
    await _precacheImages(tester);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await _precacheImages(tester);
    await expectLater(
      find.byType(KnowItWhereApp),
      matchesGoldenFile('../../docs/screens/$name.png'),
    );
  }

  screenTest('onboarding', (tester) async {
    await pump(tester, onboarding: true);
    await shot(tester, '1_onboarding');
  });

  screenTest('home empty', (tester) async {
    await pump(tester);
    await shot(tester, '2_home_empty');
  });

  screenTest('home board, index, locations, search', (tester) async {
    await seed(tester);
    await pump(tester);
    await shot(tester, '3_home_board');

    await tester.tap(find.text('Index'));
    await tester.pumpAndSettle();
    await shot(tester, '4_home_index');

    await tester.tap(find.text('Locations'));
    await tester.pumpAndSettle();
    await shot(tester, '5_home_locations');

    await tester.enterText(find.byType(TextField), 'key');
    await tester.pumpAndSettle();
    await shot(tester, '6_search');
  });

  screenTest('detail and form', (tester) async {
    await seed(tester);
    await pump(tester);
    await tester.tap(find.text('Spare Keys'));
    await tester.pumpAndSettle();
    await shot(tester, '7_detail');

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await shot(tester, '8_edit');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();
    await shot(tester, '9_add');
  });
}

/// Lets real time pass so asset and file images decode, pumping frames in
/// between because the image callbacks land in the test's fake-async zone.
Future<void> _precacheImages(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    // Starts the load; completion is observed by the pumps below.
    precacheImage(image.image, element);
  }
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// A widget test that renders real shadows. Tests draw shadows as hard
/// outlines by default, and the flag must be restored before the test ends.
void screenTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}
