import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/section_label.dart';
import '../search/search_filter.dart';
import 'grouping.dart';
import 'home_views.dart';
import 'smart_tip.dart';

enum HomeView { board, list, locations }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  Stream<List<Item>>? _items;
  HomeView _view = HomeView.board;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= AppScope.of(context).repository.watchAll();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Item item) async {
    final repo = AppScope.of(context).repository;
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(item.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            'Deleted "${item.name}"',
            style: const TextStyle(
              color: Color(0xFFFBF8F2),
              fontWeight: FontWeight.w500,
            ),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.orange,
            onPressed: () => repo.restore(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final actions = ItemActions(
      open: (item) => context.push('/item/${item.id}'),
      delete: _delete,
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Item>>(
          stream: _items,
          builder: (context, snapshot) {
            final all = snapshot.data;
            final query = _search.text.trim();
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _topBar(context)),
                if (all == null)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (query.isNotEmpty)
                  ..._searchSlivers(filterItems(all, query), query, actions)
                else ...[
                  SliverToBoxAdapter(child: _header(context)),
                  if (all.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyHome())
                  else ...[
                    SliverToBoxAdapter(child: _tabs(context, all.length)),
                    ...switch (_view) {
                      HomeView.board => boardSlivers(context, all, actions),
                      HomeView.list => indexSlivers(all, actions),
                      HomeView.locations => locationSlivers(all, actions),
                    },
                  ],
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: SmartTip(
                        day: DateTime.now().millisecondsSinceEpoch ~/ 86400000,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add item',
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final query = _search.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const _LogoTile(),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Where is my…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.orange,
                    width: 2,
                  ),
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.cancel_rounded, size: 20),
                        onPressed: () => setState(() => _search.clear()),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    // Like iOS large titles, the headline grows less than body text so the
    // content stays on screen at accessibility sizes.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Your home, remembered'),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                greeting(DateTime.now()),
                style: theme.textTheme.headlineLarge,
              ),
            ),
            Text(
              'What are you looking for?',
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs(BuildContext context, int count) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          for (final (view, label, icon) in [
            (HomeView.board, 'Board ($count)', Icons.grid_view_rounded),
            (HomeView.list, 'Index', Icons.format_list_bulleted_rounded),
            (HomeView.locations, 'Locations', Icons.place_outlined),
          ]) ...[
            _TabChip(
              label: label,
              icon: icon,
              selected: _view == view,
              onTap: () => setState(() => _view = view),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  List<Widget> _searchSlivers(
    List<Item> results,
    String query,
    ItemActions actions,
  ) {
    if (results.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            illustration: const Mascot(height: 140),
            title: 'No match for "$query"',
            message: 'Try a shorter word, or add it as a new item.',
          ),
        ),
      ];
    }
    return resultSlivers(results, actions);
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40F4632A),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onSecondary : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondary : scheme.surfaceContainerLowest,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? scheme.secondary : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            EmptyState(
              illustration: const Mascot(height: 170),
              title: 'Nothing stored yet',
              message: 'Add the first thing you want to be able to find later.',
              action: FilledButton.icon(
                onPressed: () => context.push('/add'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
