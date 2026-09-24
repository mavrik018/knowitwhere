/// Custom URL scheme used by the widget and Spotlight (SRS §4.3).
const urlScheme = 'knowitwhere';

/// Maps a deep link onto an app route, or null if it isn't one of ours.
///
/// - `knowitwhere://add` → `/add`
/// - `knowitwhere://item/{id}` → `/item/{id}`
/// - `knowitwhere://` → `/`
String? routeForDeepLink(Uri uri) {
  if (uri.scheme.toLowerCase() != urlScheme) return null;
  // `knowitwhere://item/x` parses "item" as the host; also accept `:///item/x`.
  final segments = [
    if (uri.host.isNotEmpty) uri.host.toLowerCase(),
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  return switch (segments) {
    [] => '/',
    ['add'] => '/add',
    ['item', final id] => '/item/${Uri.encodeComponent(id)}',
    _ => null,
  };
}
