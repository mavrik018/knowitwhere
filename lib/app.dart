import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'data/item_repository.dart';
import 'features/home/home_screen.dart';
import 'features/item_detail/item_detail_screen.dart';
import 'features/item_form/item_form_screen.dart';
import 'theme/app_theme.dart';

/// Routes mirror the Phase 3 deep links: `wdipit://add`, `wdipit://item/{id}`.
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

class WdipitApp extends StatefulWidget {
  const WdipitApp({super.key, required this.repository});

  final ItemRepository repository;

  @override
  State<WdipitApp> createState() => _WdipitAppState();
}

class _WdipitAppState extends State<WdipitApp> {
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
      child: MaterialApp.router(
        title: 'Where Did I Put That?',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
