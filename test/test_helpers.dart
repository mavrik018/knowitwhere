import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page's vertical scrollable (the home tabs also scroll sideways).
final verticalScrollable = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// Scrolls the page (down, or up with a negative [delta]) until [finder] is
/// on screen.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: verticalScrollable.first,
  );
  await tester.pumpAndSettle();
}

/// Scrolls the page until [finder] is on screen, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: verticalScrollable.first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Uses an iPhone 15-sized screen (393×852 points).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
