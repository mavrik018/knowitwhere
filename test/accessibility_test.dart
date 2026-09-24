import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/app.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/data/photo_store.dart';
import 'package:knowitwhere/features/home/item_card.dart';

/// SRS §7 accessibility: Dynamic Type on every screen, VoiceOver labels on
/// list rows and the Add/Edit form. Layout overflows fail these tests.
void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late Directory tmp;
  late PhotoStore photos;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('a11y_test');
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

  /// iPhone SE (3rd gen) logical size, the smallest supported screen.
  Future<void> pumpSmallScreen(WidgetTester tester, double textScale) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(KnowItWhereApp(repository: repo, photos: photos));
    await tester.pumpAndSettle();
  }

  // 3.1x is roughly iOS's largest accessibility text size (AX5).
  for (final scale in [1.0, 2.0, 3.1]) {
    group('text scale $scale', () {
      testWidgets('empty home fits', (tester) async {
        await pumpSmallScreen(tester, scale);
        expect(find.text('Nothing stored yet'), findsOneWidget);
      });

      testWidgets('home list with long names fits', (tester) async {
        await repo.add(
          name: 'Grandma’s silver anniversary cake server',
          location: 'Dining room sideboard, bottom drawer, behind the napkins',
        );
        await repo.add(name: 'Keys', location: 'Hook');
        await pumpSmallScreen(tester, scale);
        expect(find.text('Keys'), findsOneWidget);
      });

      testWidgets('no-results state fits', (tester) async {
        await repo.add(name: 'Keys', location: 'Hook');
        await pumpSmallScreen(tester, scale);
        await tester.enterText(find.byType(TextField), 'a very long query');
        await tester.pumpAndSettle();
        expect(find.textContaining('No match'), findsOneWidget);
      });

      testWidgets('add form fits, including validation errors', (tester) async {
        await pumpSmallScreen(tester, scale);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save item'));
        await tester.pumpAndSettle();
        expect(find.text('Give it a name'), findsOneWidget);
      });

      testWidgets('detail with a long location fits', (tester) async {
        await repo.add(
          name: 'Winter duvet',
          location:
              'Top shelf of the airing cupboard on the landing, in the '
              'vacuum bag under the spare pillows',
        );
        await pumpSmallScreen(tester, scale);
        await tester.tap(find.text('Winter duvet'));
        await tester.pumpAndSettle();
        expect(find.text('Stored in'), findsOneWidget);
      });
    });
  }

  testWidgets('list rows read as one VoiceOver element with name and place', (
    tester,
  ) async {
    await repo.add(name: 'Passport', location: 'Desk drawer');
    final handle = tester.ensureSemantics();
    await pumpSmallScreen(tester, 1);

    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Passport, stored in Desk drawer'),
      ),
      isSemantics(
        label: 'Passport, stored in Desk drawer',
        isButton: true,
        hasTapAction: true,
        customActions: [ItemCard.deleteAction],
      ),
    );

    // The custom action deletes, like a swipe.
    tester.semantics.performAction(
      find.semantics.byLabel('Passport, stored in Desk drawer'),
      SemanticsAction.customAction,
      args: CustomSemanticsAction.getIdentifier(ItemCard.deleteAction),
    );
    await tester.pumpAndSettle();
    expect(await repo.getAll(), isEmpty);
    handle.dispose();
  });

  testWidgets('form fields and icon buttons have spoken labels', (
    tester,
  ) async {
    await repo.add(name: 'Keys', location: 'Hook');
    final handle = tester.ensureSemantics();
    await pumpSmallScreen(tester, 1);

    await tester.tap(find.text('Keys'));
    await tester.pumpAndSettle();
    // Icon buttons are announced via their tooltip.
    for (final action in ['Edit', 'Delete']) {
      expect(
        tester.getSemantics(find.byTooltip(action)),
        isSemantics(tooltip: action, isButton: true, hasTapAction: true),
      );
    }

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('What is it')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Where is it')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Add a photo')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('meets Flutter accessibility guidelines', (tester) async {
    await repo.add(name: 'Passport', location: 'Desk drawer');
    final handle = tester.ensureSemantics();
    await pumpSmallScreen(tester, 1);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
