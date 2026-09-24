import 'package:knowitwhere/util/relative_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 24, 9);

  test('same calendar day is today', () {
    expect(relativeDate(DateTime(2026, 9, 24, 0, 1), now), 'today');
  });

  test('previous calendar day is yesterday even if under 24h ago', () {
    expect(relativeDate(DateTime(2026, 9, 23, 23), now), 'yesterday');
  });

  test('within a week shows days ago', () {
    expect(relativeDate(DateTime(2026, 9, 20), now), '4 days ago');
  });

  test('older dates show the date', () {
    expect(relativeDate(DateTime(2026, 3, 12), now), '12 Mar 2026');
  });
}
