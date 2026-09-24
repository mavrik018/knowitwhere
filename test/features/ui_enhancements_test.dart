import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/app.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/data/item_repository.dart';
import 'package:knowitwhere/data/photo_store.dart';
import 'package:knowitwhere/features/home/item_card.dart';
import 'package:knowitwhere/features/home/smart_tip.dart';
import 'package:knowitwhere/features/onboarding/onboarding_screen.dart';
import 'package:knowitwhere/theme/app_theme.dart';
import 'package:knowitwhere/widgets/pinned_photo.dart';
import 'package:knowitwhere/widgets/section_label.dart';
import 'package:knowitwhere/widgets/siri_bar.dart';

import '../test_helpers.dart';

void main() {
  group('UI Enhancements', () {
    late AppDatabase db;
    late ItemRepository repo;
    late Directory tmp;
    late PhotoStore photos;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('ui_test');
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

    test('SmartTip uses capitalized KnowItWhere in tip text and phrase', () {
      expect(SmartTip.siriPhraseShort, contains('KnowItWhere'));
      expect(SmartTip.tips.any((t) => t.contains('KnowItWhere')), isTrue);
      // Ensure lowercase 'knowitwhere' is not present in user-facing tip text.
      for (final tip in SmartTip.tips) {
        expect(tip.contains('knowitwhere'), isFalse);
      }
    });

    testWidgets('OnboardingScreen does not display SiriBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OnboardingScreen(onDone: () {})),
      );
      expect(find.byType(SiriBar), findsNothing);
      expect(find.textContaining('Hey Siri'), findsNothing);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('PinDot renders thumbpin asset image', (tester) async {
      // Scaled widgets need ScreenUtil, as in the real app.
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: designSize,
          builder: (context, _) =>
              const MaterialApp(home: Scaffold(body: PinDot(size: 28))),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/thumbpin.png',
      );
    });

    testWidgets(
      'Text form fields show circular clear button when text is entered',
      (tester) async {
        usePhoneScreen(tester);
        await tester.pumpWidget(
          KnowItWhereApp(repository: repo, photos: photos),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Add item'));
        await tester.pumpAndSettle();

        // Clear button should not be visible when field is empty.
        expect(find.byIcon(Icons.cancel_rounded), findsNothing);

        // Type in name field.
        await tester.enterText(find.byType(TextFormField).first, 'Headphones');
        await tester.pumpAndSettle();

        // Clear button should appear.
        expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

        // Tap clear button to reset the text.
        await tester.tap(find.byTooltip('Clear name'));
        await tester.pumpAndSettle();

        expect(find.text('Headphones'), findsNothing);
        expect(find.byIcon(Icons.cancel_rounded), findsNothing);
      },
    );

    testWidgets('Search field uses circular cancel button and clears on tap', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(KnowItWhereApp(repository: repo, photos: photos));
      await tester.pumpAndSettle();

      // Enter search text.
      await tester.enterText(find.byType(TextField), 'charger');
      await tester.pumpAndSettle();

      // Circular clear icon appears.
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      // Tap clear button.
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('charger'), findsNothing);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });

    testWidgets('Deleting an item shows readable snackbar with Undo action', (
      tester,
    ) async {
      await repo.add(name: 'Wallet', location: 'Nightstand');
      usePhoneScreen(tester);
      await tester.pumpWidget(KnowItWhereApp(repository: repo, photos: photos));
      await tester.pumpAndSettle();

      // Swipe to delete in Index tab or trigger delete
      await tester.tap(find.text('Index'));
      await tester.pumpAndSettle();

      await tester.drag(find.text('Wallet'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify deletion snackbar appears with Undo
      expect(find.text('Deleted "Wallet"'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Item is restored
      expect(find.text('Wallet'), findsOneWidget);
    });

    testWidgets(
      'ItemBoardCard renders as an authentic Polaroid with PinDot at top',
      (tester) async {
        await repo.add(name: 'Passport', location: 'Top drawer');
        usePhoneScreen(tester);
        await tester.pumpWidget(
          KnowItWhereApp(repository: repo, photos: photos),
        );
        await tester.pumpAndSettle();

        // In board view, ItemBoardCard is rendered with Passport and Top drawer
        expect(find.text('Passport'), findsOneWidget);
        expect(find.text('Top drawer'), findsOneWidget);
        // PinDot is rendered on the Polaroid card
        expect(find.byType(PinDot), findsWidgets);
      },
    );

    testWidgets('SectionLabel renders taped manila tag with correct text', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: designSize,
          builder: (context, _) => const MaterialApp(
            home: Scaffold(body: SectionLabel('Recent (This Week)', count: 2)),
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('RECENT (THIS WEEK) · 2'));
      expect(textWidget.style?.fontFamily, 'Poppins');
    });

    test('AppTheme light mode uses soft light orange background and Poppins font', () {
      final theme = AppTheme.light();
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFF6EE));
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Poppins');
      expect(theme.textTheme.titleMedium?.fontFamily, 'Poppins');
      expect(theme.textTheme.headlineLarge?.fontFamily, 'Poppins');
    });

    testWidgets('ItemBoardCard uses readable Poppins font for name and location', (
      tester,
    ) async {
      final item = Item(
        id: '1',
        name: 'Car Keys',
        location: 'Hallway Table',
        dateAdded: DateTime.now(),
        dateUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: designSize,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180.w,
                  child: ItemBoardCard(
                    item: item,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final nameWidget = tester.widget<Text>(find.text('Car Keys'));
      expect(nameWidget.style?.fontFamily, 'Poppins');
      expect(nameWidget.style?.fontWeight, FontWeight.w600);

      final locWidget = tester.widget<Text>(find.text('Hallway Table'));
      expect(locWidget.style?.fontFamily, 'Poppins');
      expect(locWidget.style?.fontWeight, FontWeight.w400);
    });
  });
}
