import 'package:flutter_test/flutter_test.dart';
import 'package:knowitwhere/platform/deep_links.dart';

String? route(String link) => routeForDeepLink(Uri.parse(link));

void main() {
  test('add link opens the add form', () {
    expect(route('knowitwhere://add'), '/add');
    expect(route('knowitwhere:///add'), '/add');
  });

  test('item link opens the item detail', () {
    expect(
      route('knowitwhere://item/3f2c9a1e-0000-4000-8000-000000000001'),
      '/item/3f2c9a1e-0000-4000-8000-000000000001',
    );
    expect(route('knowitwhere:///item/abc'), '/item/abc');
  });

  test('scheme and host are case-insensitive, id is kept verbatim', () {
    expect(route('KnowItWhere://Item/AbC'), '/item/AbC');
  });

  test('bare scheme opens home', () {
    expect(route('knowitwhere://'), '/');
  });

  test('item ids are URL-encoded into the route', () {
    expect(route('knowitwhere://item/a%20b'), '/item/a%20b');
  });

  test('unknown links are ignored', () {
    expect(route('https://example.com/item/1'), isNull);
    expect(route('knowitwhere://item'), isNull);
    expect(route('knowitwhere://item/1/extra'), isNull);
    expect(route('knowitwhere://settings'), isNull);
  });
}
