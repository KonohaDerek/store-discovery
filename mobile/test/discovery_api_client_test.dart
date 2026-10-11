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
    expect(response.items.single.location?.latitude, 25.0478);
    expect(response.items.single.location?.longitude, 121.5170);
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
    expect(detail.location?.latitude, 25.0478);
    expect(detail.location?.longitude, 121.5170);
    expect(detail.navigationTarget, 'https://maps.google.com/');
    expect(detail.attribution, 'Sample provider data');
  });

  test('keeps missing store detail fields explicit for the UI', () {
    final detail = StoreDetail.fromJson({
      'name': 'Unknown Store',
    });

    expect(detail.address, isNull);
    expect(detail.businessHours, isEmpty);
    expect(detail.openState, 'unknown');
    expect(detail.phone, isNull);
    expect(detail.website, isNull);
    expect(detail.navigationTarget, isNull);
    expect(detail.attribution, isNull);
    expect(detail.location, isNull);
  });

  test('ignores invalid store coordinates', () {
    final detail = StoreDetail.fromJson({
      'name': 'Invalid Location Store',
      'location': {'lat': 91, 'lng': 181},
    });

    expect(detail.location, isNull);
  });
}
