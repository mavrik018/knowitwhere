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
import 'layout/dialog_page.dart';
import 'layout/window_size.dart';
import 'platform/deep_links.dart';
import 'theme/app_theme.dart';

/// Routes mirror the Phase 3 deep links: `knowitwhere://add`, `knowitwhere://item/{id}`.
/// `/welcome` is the first-launch onboarding.
///
/// On wide windows (iPad) Add and Edit open as centred modal cards, and on
/// expanded windows an item link opens in the home screen's side inspector
/// (`/?item={id}`) instead of a separate page.
GoRouter buildRouter({
  String initialLocation = '/',
  VoidCallback? onOnboardingDone,
}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) {
    final match = _itemPath.firstMatch(state.uri.path);
    if (match == null || WindowSize.of(context) != WindowSize.expanded) {
      return null;
    }
    return Uri(path: '/', queryParameters: {'item': match[1]!}).toString();
  },
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
      builder: (context, state) =>
          HomeScreen(selectedItemId: state.uri.queryParameters['item']),
      routes: [
        GoRoute(
          path: 'add',
          pageBuilder: (context, state) =>
              adaptivePage(context, state.pageKey, const ItemFormScreen()),
        ),
        GoRoute(
          path: 'item/:id',
          builder: (context, state) =>
              ItemDetailScreen(itemId: state.pathParameters['id']!),
        ),
        // Top level (not under item/:id) so editing from the iPad inspector
        // doesn't build a detail page underneath the modal.
        GoRoute(
          path: 'edit/:id',
          pageBuilder: (context, state) => adaptivePage(
            context,
            state.pageKey,
            ItemFormScreen(itemId: state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);

final _itemPath = RegExp(r'^/item/([^/]+)$');

/// ScreenUtil design canvas for phones (logical pixels).
const designSize = Size(411, 914);

/// Phones scale from the 411×914 design. Wide windows use their own size as
/// the design size, so ScreenUtil runs at 1.0 and nothing is blown up: iPad
/// gets phone-sized type and touch targets in a tablet layout instead.
Size designSizeFor(Size window) =>
    WindowSize.ofWidth(window.width).isWide ? window : designSize;

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
        designSize: designSizeFor(MediaQuery.sizeOf(context)),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => MaterialApp.router(
          title: 'knowitwhere',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          theme: AppTheme.light(wide: WindowSize.of(context).isWide),
          darkTheme: AppTheme.light(wide: WindowSize.of(context).isWide),
          routerConfig: _router,
        ),
      ),
    );
  }
}
