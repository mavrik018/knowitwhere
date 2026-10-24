import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/app.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/data/photo_store.dart';
import 'package:knowitwhere/features/item_detail/item_detail_screen.dart';
import 'package:knowitwhere/features/item_detail/item_inspector.dart';
import 'package:knowitwhere/layout/window_size.dart';

/// iPad layouts: chosen by window width (Split View / Stage Manager aware),
/// not device model.
void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late Directory tmp;
  late PhotoStore photos;

  const landscape = Size(1180, 820); // expanded
  const portrait = Size(820, 1180); // medium
  const slideOver = Size(375, 820); // compact, e.g. Slide Over

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('tablet_test');
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

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    Stream<Uri>? deepLinks,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      KnowItWhereApp(repository: repo, photos: photos, deepLinks: deepLinks),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pressShortcut(
    WidgetTester tester,
    LogicalKeyboardKey key,
  ) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
  }

  test('window size tiers follow the width breakpoints', () {
    expect(WindowSize.ofWidth(320), WindowSize.compact);
    expect(WindowSize.ofWidth(599), WindowSize.compact);
    expect(WindowSize.ofWidth(600), WindowSize.medium);
    expect(WindowSize.ofWidth(899), WindowSize.medium);
    expect(WindowSize.ofWidth(900), WindowSize.expanded);
  });

  test('ScreenUtil scales phones from 411×914 but never scales iPad', () {
    expect(designSizeFor(const Size(393, 852)), designSize);
    expect(designSizeFor(landscape), landscape);
    expect(designSizeFor(portrait), portrait);
  });

  testWidgets('iPad sizes render at scale 1.0, not blown up', (tester) async {
    await pumpAt(tester, landscape);
    expect(ScreenUtil().scaleWidth, 1.0);
    expect(ScreenUtil().scaleHeight, 1.0);
    expect(17.sp, 17.0);
  });

  testWidgets('expanded: sidebar and toolbar Add, no floating button', (
    tester,
  ) async {
    await pumpAt(tester, landscape);

    expect(find.text('KnowItWhere'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Add item (⌘N)'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('expanded: opening an item shows the inspector beside the list', (
    tester,
  ) async {
    await repo.add(name: 'Passport', location: 'Desk drawer');
    await pumpAt(tester, landscape);

    await tester.tap(find.text('Passport'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemInspector), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
    expect(find.text('Stored in'), findsOneWidget);
    // The board is still there next to it.
    expect(find.text('KnowItWhere'), findsOneWidget);

    // Escape closes it.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ItemInspector), findsNothing);
  });

  testWidgets('expanded: an item deep link opens in the inspector', (
    tester,
  ) async {
    final item = await repo.add(name: 'Keys', location: 'Hook');
    final links = StreamController<Uri>();
    addTearDown(links.close);
    await pumpAt(tester, landscape, deepLinks: links.stream);

    links.add(Uri.parse('knowitwhere://item/${item.id}'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemInspector), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });

  testWidgets('⌘N opens Add as a modal card that Escape dismisses', (
    tester,
  ) async {
    await pumpAt(tester, landscape);

    await pressShortcut(tester, LogicalKeyboardKey.keyN);
    expect(find.text('Save item'), findsOneWidget);
    expect(find.byType(CloseButton), findsOneWidget);
    // Still the home layout underneath, not a pushed page.
    expect(find.text('KnowItWhere', skipOffstage: false), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Save item'), findsNothing);
  });

  testWidgets('⌘F focuses search', (tester) async {
    await pumpAt(tester, landscape);

    await pressShortcut(tester, LogicalKeyboardKey.keyF);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
  });

  testWidgets('medium: navigation rail, and items open as a page', (
    tester,
  ) async {
    await repo.add(name: 'Tent', location: 'Loft');
    await pumpAt(tester, portrait);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('Tent'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.byType(ItemInspector), findsNothing);
  });

  testWidgets('sidebar switches views', (tester) async {
    await repo.add(name: 'Tent', location: 'Loft');
    await repo.add(name: 'Tape', location: 'loft');
    final handle = tester.ensureSemantics();
    await pumpAt(tester, landscape);

    await tester.tap(find.text('Locations'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(r'^loft, 2 items$', caseSensitive: false)),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('narrow iPad windows (Slide Over) get the phone layout', (
    tester,
  ) async {
    await pumpAt(tester, slideOver);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('KnowItWhere'), findsNothing);
  });

  // A phone turned sideways for the camera, or an iPad window resized
  // across a breakpoint, must not swap the Add page for a modal card: the
  // swap rebuilt the form and wiped what was typed and the picked photo.
  testWidgets('resizing the window keeps an open Add form', (tester) async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    await pumpAt(tester, slideOver, deepLinks: links.stream);
    links.add(Uri.parse('knowitwhere://add'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Passport');
    await tester.enterText(fields.at(1), 'Desk drawer');

    tester.view.physicalSize = landscape * 2;
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Desk drawer'), findsOneWidget);

    tester.view.physicalSize = slideOver * 2;
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsOneWidget);

    // Once closed, the next Add follows the current width again.
    await tester.pageBack();
    await tester.pumpAndSettle();
    tester.view.physicalSize = landscape * 2;
    await tester.pumpAndSettle();
    links.add(Uri.parse('knowitwhere://add'));
    await tester.pumpAndSettle();
    expect(find.byType(CloseButton), findsOneWidget);
  });

  testWidgets('expanded layout meets accessibility guidelines', (tester) async {
    await repo.add(name: 'Passport', location: 'Desk drawer');
    final handle = tester.ensureSemantics();
    await pumpAt(tester, landscape);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
