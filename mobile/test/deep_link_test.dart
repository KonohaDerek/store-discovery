import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/deep_links/store_deep_link.dart';

void main() {
  test('builds the canonical store deep link', () {
    expect(
      StoreDeepLink.forStore('sample-cafe-1').toString(),
      'store-discovery://store/sample-cafe-1',
    );
  });

  test('extracts an opaque store id from a canonical link', () {
    expect(
      StoreDeepLink.storeIdFrom(
        Uri.parse('store-discovery://store/sample-cafe-1'),
      ),
      'sample-cafe-1',
    );
  });

  test('rejects links outside the Store Discovery contract', () {
    expect(
      StoreDeepLink.storeIdFrom(Uri.parse('https://example.com/store/1')),
      isNull,
    );
    expect(
      StoreDeepLink.storeIdFrom(Uri.parse('store-discovery://store')),
      isNull,
    );
    expect(
      StoreDeepLink.storeIdFrom(
        Uri.parse('store-discovery://store/sample-cafe-1?source=share'),
      ),
      isNull,
    );
  });
}
