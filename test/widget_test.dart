import 'dart:async';
import 'dart:io';

import 'package:knowitwhere/app.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/data/photo_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late Directory tmp;
  late PhotoStore photos;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('widget_test');
    photos = PhotoStore(tmp);
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repo = ItemRepository(db);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(KnowItWhereApp(repository: repo, photos: photos));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state when nothing is stored', (tester) async {
    await pumpApp(tester);

    expect(find.text('Nothing stored yet'), findsOneWidget);
  });

  testWidgets('adds an item through the form and lists it', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();

    // Validation blocks an empty save.
    await scrollAndTap(tester, find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('Give it a name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Passport');
    await tester.enterText(find.byType(TextFormField).at(1), 'Desk drawer');
    await scrollAndTap(tester, find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing stored yet'), findsNothing);
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Desk drawer'), findsOneWidget);
  });

  testWidgets('search filters live and shows a distinct no-results state', (
    tester,
  ) async {
    await repo.add(name: 'Passport', location: 'Desk drawer');
    await repo.add(name: 'HDMI cable', location: 'TV cabinet');
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'hdmi');
    await tester.pumpAndSettle();
    expect(find.text('HDMI cable'), findsOneWidget);
    expect(find.text('Passport'), findsNothing);

    await tester.enterText(find.byType(TextField), 'umbrella');
    await tester.pumpAndSettle();
    expect(find.text('No match for "umbrella"'), findsOneWidget);
    expect(find.text('Nothing stored yet'), findsNothing);
  });

  testWidgets('detail shows the location and edit updates it', (tester) async {
    await repo.add(name: 'Keys', location: 'Hook');
    await pumpApp(tester);

    await scrollAndTap(tester, find.text('Keys'));
    await tester.pumpAndSettle();
    expect(find.text('Stored in'), findsOneWidget);
    expect(find.text('Hook'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Bowl by door');
    await scrollAndTap(tester, find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Bowl by door'), findsOneWidget);
    expect((await repo.getAll()).single.location, 'Bowl by door');
  });

  testWidgets('delete from detail removes the item', (tester) async {
    await repo.add(name: 'Keys', location: 'Hook');
    await pumpApp(tester);

    await scrollAndTap(tester, find.text('Keys'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing stored yet'), findsOneWidget);
    expect(await repo.getAll(), isEmpty);
  });

  testWidgets('items with a photo show it in the list and detail', (
    tester,
  ) async {
    await repo.add(
      name: 'Tent',
      location: 'Loft',
      photoPath: 'photos/missing.jpg',
    );
    await pumpApp(tester);

    expect(find.byType(Image), findsOneWidget);

    await scrollAndTap(tester, find.text('Tent'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Photo of Tent'), findsOneWidget);
  });

  testWidgets('deep links open the add form and item detail', (tester) async {
    final item = await repo.add(name: 'Passport', location: 'Desk drawer');
    final links = StreamController<Uri>();
    addTearDown(links.close);
    usePhoneScreen(tester);
    await tester.pumpWidget(
      KnowItWhereApp(repository: repo, photos: photos, deepLinks: links.stream),
    );
    await tester.pumpAndSettle();

    links.add(Uri.parse('knowitwhere://item/${item.id}'));
    await tester.pumpAndSettle();
    expect(find.text('Stored in'), findsOneWidget);

    links.add(Uri.parse('knowitwhere://add'));
    await tester.pumpAndSettle();
    expect(find.text('Save item'), findsOneWidget);

    // Unknown links are ignored.
    links.add(Uri.parse('knowitwhere://nope'));
    await tester.pumpAndSettle();
    expect(find.text('Save item'), findsOneWidget);
  });

  testWidgets('first launch shows onboarding until Get started', (
    tester,
  ) async {
    var done = false;
    usePhoneScreen(tester);
    await tester.pumpWidget(
      KnowItWhereApp(
        repository: repo,
        photos: photos,
        showOnboarding: true,
        onOnboardingDone: () => done = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Never lose it again'), findsOneWidget);
    expect(
      find.textContaining('where’s my passport in knowitwhere'),
      findsOneWidget,
    );

    await scrollAndTap(tester, find.text('Get started'));
    expect(done, isTrue);
    expect(find.text('Nothing stored yet'), findsOneWidget);
  });

  testWidgets('Index and Locations tabs list items', (tester) async {
    await repo.add(name: 'Tent', location: 'Loft');
    await repo.add(name: 'Tape', location: 'loft');
    final handle = tester.ensureSemantics();
    await pumpApp(tester);

    await tester.tap(find.text('Index'));
    await tester.pumpAndSettle();
    expect(find.text('T'), findsOneWidget);
    expect(find.text('Tape'), findsOneWidget);
    expect(find.text('Tent'), findsOneWidget);

    // The tab row scrolls sideways on narrow screens.
    await tester.ensureVisible(find.text('Locations'));
    await tester.tap(find.text('Locations'));
    await tester.pumpAndSettle();
    // Both spellings merge into one group of two.
    expect(
      find.bySemanticsLabel(RegExp(r'^loft, 2 items$', caseSensitive: false)),
      findsOneWidget,
    );
    handle.dispose();
  });
}
