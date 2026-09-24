import '../../data/database.dart';

/// Live search (FR2.1, FR2.3).
///
/// Case-insensitive substring match on name and location. Results are ranked
/// in tiers — name starts with the query, then a word in the name starts with
/// it, then any other match — and each tier is ordered most recently updated
/// first. An empty query returns everything by recency.
List<Item> filterItems(Iterable<Item> items, String query) {
  final byRecency = items.toList()
    ..sort((a, b) => b.dateUpdated.compareTo(a.dateUpdated));
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return byRecency;

  final tiers = [<Item>[], <Item>[], <Item>[]];
  for (final item in byRecency) {
    final name = item.name.toLowerCase();
    if (name.startsWith(q)) {
      tiers[0].add(item);
    } else if (name.contains(q) &&
        name.split(_wordBreak).any((w) => w.startsWith(q))) {
      tiers[1].add(item);
    } else if (name.contains(q) || item.location.toLowerCase().contains(q)) {
      tiers[2].add(item);
    }
  }
  return tiers.expand((t) => t).toList();
}

final _wordBreak = RegExp(r'[\s\-_/.,]+');
