import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../layout/window_size.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/section_label.dart';
import '../item_detail/item_inspector.dart';
import '../search/search_filter.dart';
import 'grouping.dart';
import 'home_screen.dart';
import 'home_search_field.dart';
import 'home_views.dart';
import 'smart_tip.dart';

/// iPad layout of the home screen (window width ≥ 600).
///
/// A structural redesign rather than a scaled-up phone: navigation lives in
/// a sidebar (expanded) or rail (medium), search and Add sit in the top
/// toolbar, the board becomes a multi-column grid, and on expanded windows
/// an opened item shows in a trailing inspector beside the list. Type and
/// touch targets stay phone-sized (ScreenUtil runs at 1.0 here).
class TabletHome extends StatelessWidget {
  const TabletHome({
    super.key,
    required this.windowSize,
    required this.items,
    required this.search,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.view,
    required this.onViewChanged,
    required this.selectedId,
    required this.actions,
    required this.onCloseInspector,
  });

  final WindowSize windowSize;

  /// Null while the first query is loading.
  final List<Item>? items;
  final TextEditingController search;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchChanged;
  final HomeView view;
  final ValueChanged<HomeView> onViewChanged;

  /// Item shown in the inspector (expanded windows only).
  final String? selectedId;
  final ItemActions actions;
  final VoidCallback onCloseInspector;

  bool get _expanded => windowSize == WindowSize.expanded;

  @override
  Widget build(BuildContext context) {
    final items = this.items;
    final showInspector = _expanded && selectedId != null;
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_expanded)
              _Sidebar(
                view: view,
                itemCount: items?.length ?? 0,
                locationCount: items == null
                    ? 0
                    : groupByLocation(items).length,
                onViewChanged: onViewChanged,
              )
            else
              _Rail(view: view, onViewChanged: onViewChanged),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Toolbar(
                    search: search,
                    searchFocusNode: searchFocusNode,
                    onSearchChanged: onSearchChanged,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          if (items != null)
                            ..._content(context, items, constraints.maxWidth),
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showInspector) ...[
              const VerticalDivider(width: 1, thickness: 1),
              SizedBox(
                width: TabletMetrics.inspectorWidth,
                child: ItemInspector(
                  key: ValueKey(selectedId),
                  itemId: selectedId!,
                  onClose: onCloseInspector,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, List<Item> items, double width) {
    const padding = EdgeInsets.symmetric(horizontal: TabletMetrics.gutter);
    final listLayout = ListLayout(
      padding: padding,
      maxWidth: TabletMetrics.readableWidth,
      selectedId: selectedId,
    );
    final query = search.text.trim();
    if (query.isNotEmpty) {
      final results = filterItems(items, query);
      if (results.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _CenteredEmpty(
              title: 'No match for "$query"',
              message: 'Try a shorter word, or add it as a new item.',
            ),
          ),
        ];
      }
      return resultSlivers(results, actions, layout: listLayout);
    }
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _CenteredEmpty(
            title: 'Nothing stored yet',
            message: 'Add the first thing you want to be able to find later.',
            action: FilledButton.icon(
              onPressed: () => context.push('/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first item'),
            ),
          ),
        ),
      ];
    }
    // Column count follows the space: 2–3 in portrait, 3–5 in landscape.
    const gap = 12.0;
    final usable = width - 2 * TabletMetrics.gutter;
    final columns = ((usable + gap) / (TabletMetrics.boardCardWidth + gap))
        .floor()
        .clamp(2, 6);
    return [
      ...switch (view) {
        HomeView.board => boardSlivers(
          context,
          items,
          actions,
          columns: columns,
          padding: padding,
          selectedId: selectedId,
          hover: true,
        ),
        HomeView.list => indexSlivers(items, actions, layout: listLayout),
        HomeView.locations => locationSlivers(
          items,
          actions,
          layout: listLayout,
        ),
      },
      // The rail has no room for the tip; the sidebar shows it instead.
      if (!_expanded)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            TabletMetrics.gutter,
            28,
            TabletMetrics.gutter,
            0,
          ),
          sliver: SliverConstrainedCrossAxis(
            maxExtent: TabletMetrics.readableWidth,
            sliver: SliverToBoxAdapter(child: SmartTip(day: _today)),
          ),
        ),
    ];
  }
}

int get _today => DateTime.now().millisecondsSinceEpoch ~/ 86400000;

/// Greeting on the left; search and Add on the right, like Mail or Notes.
/// Stacks the search under the title when the pane is narrow.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.searchFocusNode,
    required this.onSearchChanged,
  });

  final TextEditingController search;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Your home, remembered'),
          const SizedBox(height: 4),
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
    );
    final field = HomeSearchField(
      controller: search,
      focusNode: searchFocusNode,
      onChanged: onSearchChanged,
    );
    final add = Tooltip(
      message: 'Add item (⌘N)',
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TabletMetrics.gutter,
        20,
        TabletMetrics.gutter,
        8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 780) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: title),
                const SizedBox(width: 24),
                SizedBox(width: 340, child: field),
                const SizedBox(width: 12),
                add,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 16),
                  add,
                ],
              ),
              const SizedBox(height: 16),
              field,
            ],
          );
        },
      ),
    );
  }
}

/// Persistent leading sidebar for expanded windows.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.view,
    required this.itemCount,
    required this.locationCount,
    required this.onViewChanged,
  });

  final HomeView view;
  final int itemCount;
  final int locationCount;
  final ValueChanged<HomeView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: TabletMetrics.sidebarWidth,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  const _LogoMark(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'KnowItWhere',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final (v, label, icon, count) in [
              (HomeView.board, 'Board', Icons.grid_view_rounded, itemCount),
              (
                HomeView.list,
                'Index',
                Icons.format_list_bulleted_rounded,
                null,
              ),
              (
                HomeView.locations,
                'Locations',
                Icons.place_outlined,
                locationCount,
              ),
            ])
              _SidebarItem(
                label: label,
                icon: icon,
                count: count,
                selected: view == v,
                onTap: () => onViewChanged(v),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SmartTip(day: _today),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final fg = selected ? palette.accentText : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: fg,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (count != null)
                      Text(
                        '$count',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation rail for medium windows (iPad portrait, 1/2 Split View).
class _Rail extends StatelessWidget {
  const _Rail({required this.view, required this.onViewChanged});

  final HomeView view;
  final ValueChanged<HomeView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return NavigationRail(
      selectedIndex: HomeView.values.indexOf(view),
      onDestinationSelected: (i) => onViewChanged(HomeView.values[i]),
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      indicatorColor: palette.accentSoft,
      selectedIconTheme: IconThemeData(color: palette.accentText),
      selectedLabelTextStyle: theme.textTheme.labelMedium?.copyWith(
        color: palette.accentText,
        letterSpacing: 0,
      ),
      unselectedLabelTextStyle: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0,
      ),
      leading: const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 16),
        child: _LogoMark(size: 44),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: Text('Board'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.format_list_bulleted_rounded),
          label: Text('Index'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.place_outlined),
          label: Text('Locations'),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Empty and no-results states: centred with a readable width instead of
/// stretching across the canvas.
class _CenteredEmpty extends StatelessWidget {
  const _CenteredEmpty({
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: EmptyState(
            illustration: const Mascot(height: 160),
            title: title,
            message: message,
            action: action,
          ),
        ),
      ),
    );
  }
}
