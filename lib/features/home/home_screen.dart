import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../widgets/empty_state.dart';
import '../search/search_filter.dart';
import 'item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  Stream<List<Item>>? _items;

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
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.name}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.restore(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Item>>(
          stream: _items,
          builder: (context, snapshot) {
            final all = snapshot.data;
            final query = _search.text;
            final results = all == null ? null : filterItems(all, query);
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Where did I put that?',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search your things',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        setState(() => _search.clear()),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (all == null)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (all.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nothing stored yet',
                      message:
                          'Add the first thing you want to be able to find '
                          'later.',
                    ),
                  )
                else if (results!.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No match for "${query.trim()}"',
                      message: 'Try a shorter word, or add it as a new item.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = results[i];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _delete(item),
                          background: const _DeleteBackground(),
                          child: ItemCard(
                            item: item,
                            onTap: () => context.push('/item/${item.id}'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        label: 'Delete',
        child: Icon(Icons.delete_outline, color: scheme.onError),
      ),
    );
  }
}
