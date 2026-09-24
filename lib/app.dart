import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'data/item_repository.dart';
import 'data/photo_store.dart';
import 'features/home/home_screen.dart';
import 'features/item_detail/item_detail_screen.dart';
import 'features/item_form/item_form_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'platform/deep_links.dart';
import 'theme/app_theme.dart';

/// Routes mirror the Phase 3 deep links: `knowitwhere://add`, `knowitwhere://item/{id}`.
/// `/welcome` is the first-launch onboarding.
GoRouter buildRouter({
  String initialLocation = '/',
  VoidCallback? onOnboardingDone,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => OnboardingScreen(
        onDone: () {
          onOnboardingDone?.call();
          context.go('/');
        },
      ),
    ),
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

/// ScreenUtil design canvas (logical pixels).
const designSize = Size(411, 914);

class KnowItWhereApp extends StatefulWidget {
  const KnowItWhereApp({
    super.key,
    required this.repository,
    required this.photos,
    this.deepLinks,
    this.showOnboarding = false,
    this.onOnboardingDone,
  });

  final ItemRepository repository;
  final PhotoStore photos;

  /// Incoming `knowitwhere://` links, including the one that launched the app.
  final Stream<Uri>? deepLinks;

  /// First launch: start on the onboarding screen.
  final bool showOnboarding;

  /// Called when onboarding is finished, to remember it.
  final VoidCallback? onOnboardingDone;

  @override
  State<KnowItWhereApp> createState() => _KnowItWhereAppState();
}

class _KnowItWhereAppState extends State<KnowItWhereApp> {
  late final _router = buildRouter(
    initialLocation: widget.showOnboarding ? '/welcome' : '/',
    onOnboardingDone: widget.onOnboardingDone,
  );
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _deepLinkSub = widget.deepLinks?.listen(_openDeepLink);
  }

  void _openDeepLink(Uri uri) {
    final route = routeForDeepLink(uri);
    if (route != null) _router.go(route);
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: widget.repository,
      photos: widget.photos,
      // Sizes in the app are authored against a 411×914 design and scaled
      // to the device with .w / .h / .r / .sp. The theme is built inside the
      // builder so it can use them.
      child: ScreenUtilInit(
        designSize: designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => MaterialApp.router(
          title: 'knowitwhere',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          theme: AppTheme.light(),
          darkTheme: AppTheme.light(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
