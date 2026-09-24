import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'data/item_repository.dart';
import 'data/photo_store.dart';
import 'features/home/home_screen.dart';
import 'features/item_detail/item_detail_screen.dart';
import 'features/item_form/item_form_screen.dart';
import 'theme/app_theme.dart';

/// Routes mirror the Phase 3 deep links: `knowitwhere://add`, `knowitwhere://item/{id}`.
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const ItemFormScreen(),
        ),
        GoRoute(
          path: 'item/:id',
          builder: (context, state) =>
              ItemDetailScreen(itemId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  ItemFormScreen(itemId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
  ],
);

class KnowItWhereApp extends StatefulWidget {
  const KnowItWhereApp({
    super.key,
    required this.repository,
    required this.photos,
  });

  final ItemRepository repository;
  final PhotoStore photos;

  @override
  State<KnowItWhereApp> createState() => _KnowItWhereAppState();
}

class _KnowItWhereAppState extends State<KnowItWhereApp> {
  final _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: widget.repository,
      photos: widget.photos,
      child: MaterialApp.router(
        title: 'knowitwhere',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
