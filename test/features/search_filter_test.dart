import 'package:discoverly/data/database.dart';
import 'package:discoverly/features/search/search_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(String name, String location, int minutesAgo) {
  final t = DateTime(2026, 1, 1).subtract(Duration(minutes: minutesAgo));
  return Item(
    id: name,
    name: name,
    location: location,
    dateAdded: t,
    dateUpdated: t,
  );
}

List<String> _names(List<Item> items) => items.map((i) => i.name).toList();

void main() {
  final items = [
    _item('HDMI cable', 'Drawer 2', 30),
    _item('Passport', 'Desk drawer', 10),
    _item('Cable ties', 'Garage shelf', 20),
    _item('USB-C cable', 'Backpack', 5),
    _item('Spare keys', 'Kitchen cable box', 1),
  ];

  test('empty or blank query returns all items by recency', () {
    final expected = [
      'Spare keys',
      'USB-C cable',
      'Passport',
      'Cable ties',
      'HDMI cable',
    ];
    expect(_names(filterItems(items, '')), expected);
    expect(_names(filterItems(items, '   ')), expected);
  });

  test('matching is case-insensitive', () {
    expect(_names(filterItems(items, 'PASSPORT')), ['Passport']);
    expect(_names(filterItems(items, 'passp')), ['Passport']);
  });

  test('matches location as well as name', () {
    expect(_names(filterItems(items, 'drawer')), ['Passport', 'HDMI cable']);
  });

  test('ranks name prefix, then word prefix, then other matches', () {
    expect(_names(filterItems(items, 'cable')), [
      'Cable ties', // name starts with query
      'USB-C cable', // word prefix, more recent
      'HDMI cable', // word prefix, older
      'Spare keys', // location match only
    ]);
  });

  test('substring inside a word still matches', () {
    expect(_names(filterItems(items, 'port')), ['Passport']);
  });

  test('no matches returns empty list', () {
    expect(filterItems(items, 'umbrella'), isEmpty);
  });
}
