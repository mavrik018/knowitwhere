import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../app_scope.dart';
import '../../data/database.dart';
import '../../layout/window_size.dart';
import '../../theme/app_theme.dart';
import '../../widgets/undo_delete.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/section_label.dart';
import '../search/search_filter.dart';
import 'grouping.dart';
import 'home_search_field.dart';
import 'home_views.dart';
import 'smart_tip.dart';
import 'tablet_home.dart';

enum HomeView { board, list, locations }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.selectedItemId});

  /// Item to open in the iPad inspector, from a deep link (`/?item={id}`).
  final String? selectedItemId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  Stream<List<Item>>? _items;
  HomeView _view = HomeView.board;

  /// Item open in the inspector on expanded (iPad landscape) windows.
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedItemId;
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (widget.selectedItemId != null &&
        widget.selectedItemId != old.selectedItemId) {
      _selectedId = widget.selectedItemId;
    }
  }

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
    showDeletedSnackBar(messenger, repo, item);
  }

  /// Expanded windows open items in the side inspector; everything else
  /// pushes the detail page.
  void _open(Item item) {
    _searchFocusNode.unfocus();
    if (WindowSize.of(context) == WindowSize.expanded) {
      setState(() => _selectedId = item.id);
    } else {
      context.push('/item/${item.id}');
    }
  }

  void _closeInspector() {
    setState(() => _selectedId = null);
    // Drop a deep-linked `?item=` so the same link can open it again later.
    if (widget.selectedItemId != null) context.go('/');
  }

  void _add() {
    _searchFocusNode.unfocus();
    context.push('/add');
  }

  /// Escape closes the inspector first, then clears the search.
  void _escape() {
    if (_selectedId != null && WindowSize.of(context) == WindowSize.expanded) {
      _closeInspector();
    } else if (_search.text.isNotEmpty) {
      setState(_search.clear);
    } else {
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = ItemActions(open: _open, delete: _delete);
    final windowSize = WindowSize.of(context);
    // Hardware keyboard shortcuts, as in iPadOS system apps.
    return CallbackShortcuts(
      bindings: {
        for (final meta in [true, false]) ...{
          SingleActivator(LogicalKeyboardKey.keyF, meta: meta, control: !meta):
              _searchFocusNode.requestFocus,
          SingleActivator(LogicalKeyboardKey.keyN, meta: meta, control: !meta):
              _add,
        },
        const SingleActivator(LogicalKeyboardKey.escape): _escape,
      },
      child: Focus(
        autofocus: true,
        child: windowSize.isWide
            ? StreamBuilder<List<Item>>(
                stream: _items,
                builder: (context, snapshot) => TabletHome(
                  windowSize: windowSize,
                  items: snapshot.data,
                  search: _search,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: () => setState(() {}),
                  view: _view,
                  onViewChanged: (view) => setState(() => _view = view),
                  selectedId: _selectedId,
                  actions: actions,
                  onCloseInspector: _closeInspector,
                ),
              )
            : _phone(context, actions),
      ),
    );
  }

  Widget _phone(BuildContext context, ItemActions actions) {
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
                        ..._searchSlivers(
                          filterItems(all, query),
                          query,
                          actions,
                        )
                      else ...[
                        SliverToBoxAdapter(child: _header(context)),
                        if (all.isEmpty)
                          const SliverToBoxAdapter(child: _EmptyHome())
                        else ...[
                          SliverToBoxAdapter(child: _tabs(context, all.length)),
                          ...switch (_view) {
                            HomeView.board => boardSlivers(
                              context,
                              all,
                              actions,
                            ),
                            HomeView.list => indexSlivers(all, actions),
                            HomeView.locations => locationSlivers(all, actions),
                          },
                        ],
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                          sliver: SliverToBoxAdapter(
                            child: SmartTip(
                              day:
                                  DateTime.now().millisecondsSinceEpoch ~/
                                  86400000,
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
              onPressed: _add,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: Row(
        children: [
          const _LogoTile(),
          SizedBox(width: 10.w),
          Expanded(
            child: HomeSearchField(
              controller: _search,
              focusNode: _searchFocusNode,
              onChanged: () => setState(() {}),
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
