import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/api/discovery_api_client.dart';

void main() {
  test('parses a discovery response without provider-specific fields', () {
    final response = DiscoveryResponse.fromJson({
      'items': [
        {
          'storeId': 'sample-cafe-1',
          'name': 'North Gate Coffee',
          'categories': ['food.cafe'],
          'distanceMeters': 350,
          'openState': 'open',
          'addressSummary': 'Taipei',
          'location': {'lat': 25.0478, 'lng': 121.5170},
          'source': 'sample',
        },
      ],
      'nextCursor': null,
    });

    expect(response.items.single.name, 'North Gate Coffee');
    expect(response.items.single.storeId, 'sample-cafe-1');
    expect(response.items.single.categories, ['food.cafe']);
    expect(response.items.single.distanceMeters, 350);
    expect(response.items.single.openState, 'open');
  });

  test('parses store detail fields', () {
    final detail = StoreDetail.fromJson({
      'storeId': 'sample-cafe-1',
      'name': 'North Gate Coffee',
      'categories': ['food.cafe'],
      'distanceMeters': 350,
      'openState': 'open',
      'addressSummary': 'Taipei',
      'location': {'lat': 25.0478, 'lng': 121.5170},
      'source': 'sample',
      'fullAddress': '100 Zhongxiao West Road, Taipei',
      'businessHours': ['09:00–18:00'],
      'phone': null,
      'website': null,
      'navigationTarget': 'https://maps.google.com/',
      'attribution': 'Sample provider data',
    });

    expect(detail.name, 'North Gate Coffee');
    expect(detail.businessHours, ['09:00–18:00']);
    expect(detail.openState, 'open');
  });
}
