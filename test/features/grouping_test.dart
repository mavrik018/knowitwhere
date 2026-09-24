import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/data/database.dart';
import 'package:knowitwhere/features/home/grouping.dart';

final _now = DateTime(2026, 9, 24, 10);

Item _item(String name, String location, DateTime updated) => Item(
  id: name,
  name: name,
  location: location,
  dateAdded: updated,
  dateUpdated: updated,
);

List<String> _names(ItemSection s) => s.items.map((i) => i.name).toList();

void main() {
  group('groupByRecency', () {
    test('splits into this week, earlier this month and older', () {
      final sections = groupByRecency([
        _item('Old', 'x', DateTime(2026, 8, 30)),
        _item('Today', 'x', DateTime(2026, 9, 24, 9)),
        _item('Ten days', 'x', DateTime(2026, 9, 14)),
        _item('Three days', 'x', DateTime(2026, 9, 21)),
      ], _now);

      expect(sections.map((s) => s.title), [
        'Recent (this week)',
        'Earlier this month',
        'Older',
      ]);
      expect(_names(sections[0]), ['Today', 'Three days']);
      expect(_names(sections[1]), ['Ten days']);
      expect(_names(sections[2]), ['Old']);
    });

    test('a recent item from last month counts as this week', () {
      final sections = groupByRecency([
        _item('Last month but recent', 'x', DateTime(2026, 9, 28)),
      ], DateTime(2026, 10, 2));
      expect(sections.single.title, 'Recent (this week)');
    });

    test('empty sections are left out', () {
      expect(groupByRecency([], _now), isEmpty);
    });
  });

  test('groupAlphabetically sorts A–Z with non-letters last', () {
    final sections = groupAlphabetically([
      _item('tent', 'x', _now),
      _item('140W charger', 'x', _now),
      _item('Passport', 'x', _now),
      _item('Tape', 'x', _now),
    ]);
    expect(sections.map((s) => s.title), ['P', 'T', '#']);
    expect(_names(sections[1]), ['Tape', 'tent']);
    expect(_names(sections[2]), ['140W charger']);
  });

  test('groupByLocation merges case and spacing variants', () {
    final sections = groupByLocation([
      _item('Keys', 'Hall  drawer', DateTime(2026, 9, 1)),
      _item('Tape', 'hall drawer', DateTime(2026, 9, 20)),
      _item('Tent', 'Loft', DateTime(2026, 9, 10)),
    ]);
    expect(sections.map((s) => s.title), ['hall drawer', 'Loft']);
    expect(_names(sections[0]), ['Tape', 'Keys']);
  });

  test('greeting follows the time of day', () {
    expect(greeting(DateTime(2026, 1, 1, 7)), 'Good morning.');
    expect(greeting(DateTime(2026, 1, 1, 13)), 'Good afternoon.');
    expect(greeting(DateTime(2026, 1, 1, 21)), 'Good evening.');
    expect(greeting(DateTime(2026, 1, 1, 2)), 'Good evening.');
  });
}
