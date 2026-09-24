import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
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
      open: (item) {
        _searchFocusNode.unfocus();
        context.push('/item/${item.id}');
      },
      delete: _delete,
    );
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () => _searchFocusNode.unfocus(),
      child: FocusScope(
        autofocus: false,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: StreamBuilder<List<Item>>(
                stream: _items,
                builder: (context, snapshot) {
                  final all = snapshot.data;
                  final query = _search.text.trim();
                  return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                          sliver: SliverToBoxAdapter(
                            child: SmartTip(
                              day:
                                  DateTime.now().millisecondsSinceEpoch ~/ 86400000,
                            ),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                    ],
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: 'Add item',
              onPressed: () {
                _searchFocusNode.unfocus();
                context.push('/add');
              },
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final query = _search.text;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: Row(
        children: [
          const _LogoTile(),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _search,
              focusNode: _searchFocusNode,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Where is my…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(
                    color: AppColors.orange,
                    width: 2,
                  ),
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: Icon(Icons.cancel_rounded, size: 20.r),
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
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Your home, remembered'),
            SizedBox(height: 6.h),
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
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
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
            SizedBox(width: 8.w),
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
            illustration: Mascot(height: 110.h),
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
        width: 48.r,
        height: 48.r,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40F4632A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.white,
          size: 24.r,
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
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18.r, color: fg),
                SizedBox(width: 6.w),
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
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          children: [
            EmptyState(
              illustration: Mascot(height: 130.h),
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
