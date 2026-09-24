import '../../data/database.dart';

/// A titled group of items on the home screen.
class ItemSection {
  const ItemSection(this.title, this.items);

  final String title;
  final List<Item> items;
}

/// Board view: "Recent (this week)", "Earlier this month", "Older".
/// Empty sections are omitted; items stay most recent first.
List<ItemSection> groupByRecency(Iterable<Item> items, DateTime now) {
  final weekAgo = now.subtract(const Duration(days: 7));
  final recent = <Item>[];
  final thisMonth = <Item>[];
  final older = <Item>[];
  final sorted = items.toList()
    ..sort((a, b) => b.dateUpdated.compareTo(a.dateUpdated));
  for (final item in sorted) {
    final updated = item.dateUpdated;
    if (updated.isAfter(weekAgo)) {
      recent.add(item);
    } else if (updated.year == now.year && updated.month == now.month) {
      thisMonth.add(item);
    } else {
      older.add(item);
    }
  }
  return [
    if (recent.isNotEmpty) ItemSection('Recent (this week)', recent),
    if (thisMonth.isNotEmpty) ItemSection('Earlier this month', thisMonth),
    if (older.isNotEmpty) ItemSection('Older', older),
  ];
}

/// Index view: A–Z by name, one section per first letter ("#" for the rest).
List<ItemSection> groupAlphabetically(Iterable<Item> items) {
  final sorted = items.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final sections = <String, List<Item>>{};
  for (final item in sorted) {
    final first = item.name.isEmpty ? '' : item.name[0].toUpperCase();
    final key = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
    sections.putIfAbsent(key, () => []).add(item);
  }
  final keys = sections.keys.toList()
    ..sort((a, b) => a == '#' ? 1 : (b == '#' ? -1 : a.compareTo(b)));
  return [for (final k in keys) ItemSection(k, sections[k]!)];
}

/// Locations view: items sharing a location (ignoring case and extra
/// spaces), alphabetical by place. A group is titled with the spelling of
/// its most recently updated item; items inside are most recent first.
List<ItemSection> groupByLocation(Iterable<Item> items) {
  final sorted = items.toList()
    ..sort((a, b) => b.dateUpdated.compareTo(a.dateUpdated));
  final groups = <String, List<Item>>{};
  for (final item in sorted) {
    final key = item.location.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    groups.putIfAbsent(key, () => []).add(item);
  }
  final keys = groups.keys.toList()..sort();
  return [
    for (final k in keys)
      ItemSection(groups[k]!.first.location.trim(), groups[k]!),
  ];
}

/// "Good morning." / "Good afternoon." / "Good evening."
String greeting(DateTime now) {
  if (now.hour >= 5 && now.hour < 12) return 'Good morning.';
  if (now.hour >= 12 && now.hour < 18) return 'Good afternoon.';
  return 'Good evening.';
}
