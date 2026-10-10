import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/api/discovery_api_client.dart';
import 'package:store_discovery/location/location_service.dart';
import 'package:store_discovery/main.dart';

class FixtureDiscoveryClient extends DiscoveryApiClient {
  FixtureDiscoveryClient({this.failDiscovery = false})
      : super(baseUri: Uri.parse('http://fixture'));

  final bool failDiscovery;
  var searchCalls = 0;
  String? lastQuery;
  String? lastCategory;
  String? lastArea;

  @override
  Future<DiscoveryResponse> discover({
    required String query,
    String? category,
    String? area,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
    searchCalls++;
    lastQuery = query;
    lastCategory = category;
    lastArea = area;
    if (failDiscovery) {
      throw const DiscoveryApiException(
        DiscoveryFailure.unavailable,
        'The discovery service is unavailable. Try again.',
      );
    }

    return const DiscoveryResponse(
      items: [
        StoreSummary(
          storeId: 'sample-cafe-1',
          name: 'North Gate Coffee',
          categories: ['food.cafe'],
          distanceMeters: 350,
          addressSummary: '100 Zhongxiao West Road, Taipei',
          openState: 'open',
        ),
      ],
    );
  }

  @override
  Future<StoreDetail> getStore(String storeId) async {
    return const StoreDetail(
      name: 'North Gate Coffee',
      address: '100 Zhongxiao West Road, Taipei',
      businessHours: ['09:00–18:00'],
      openState: 'open',
      phone: '02-1234-5678',
      website: 'https://example.com',
      navigationTarget: 'https://maps.google.com/',
      attribution: 'Fixture provider data',
    );
  }
}

class FixtureLocationService implements LocationService {
  @override
  Future<LocationPoint> currentLocation() async =>
      const LocationPoint(latitude: 25.0478, longitude: 121.5170);
}

Future<void> searchWithManualArea(
  WidgetTester tester,
  String query,
) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.enterText(find.byType(TextField).last, 'Taipei');
  await tester.tap(find.text('Search'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('completes discovery through store detail', (tester) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(apiClient: FixtureDiscoveryClient()),
    );

    await searchWithManualArea(tester, 'cafe');

    expect(find.text('North Gate Coffee'), findsOneWidget);
    await tester.tap(find.text('North Gate Coffee'));
    await tester.pumpAndSettle();

    expect(find.text('Store details'), findsOneWidget);
    expect(find.text('100 Zhongxiao West Road, Taipei'), findsOneWidget);
    expect(find.text('09:00–18:00'), findsOneWidget);
    expect(find.text('02-1234-5678'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.text('https://maps.google.com/'), findsOneWidget);
    expect(find.text('Fixture provider data'), findsOneWidget);
  });

  testWidgets('shows provider failure with a retry action', (tester) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(
        apiClient: FixtureDiscoveryClient(failDiscovery: true),
      ),
    );

    await searchWithManualArea(tester, 'cafe');

    expect(
      find.text('The discovery service is unavailable. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('accepts a category without a keyword', (tester) async {
    final client = FixtureDiscoveryClient();
    await tester.pumpWidget(StoreDiscoveryApp(apiClient: client));

    await tester.enterText(find.byType(TextField).at(1), 'food.cafe');
    await tester.enterText(find.byType(TextField).last, 'Taipei');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(client.lastQuery, isEmpty);
    expect(client.lastCategory, 'food.cafe');
    expect(find.text('North Gate Coffee'), findsOneWidget);
  });

  testWidgets('repeats and clears recent manual searches', (tester) async {
    final client = FixtureDiscoveryClient();
    await tester.pumpWidget(StoreDiscoveryApp(apiClient: client));

    await searchWithManualArea(tester, 'cafe');

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('cafe · Taipei'), findsOneWidget);

    await tester.tap(find.text('cafe · Taipei'));
    await tester.pumpAndSettle();

    expect(client.searchCalls, 2);
    expect(client.lastQuery, 'cafe');
    expect(client.lastArea, 'Taipei');

    await tester.tap(find.text('Clear recent searches'));
    expect(find.text('Recent searches'), findsNothing);
  });

  testWidgets('keeps only the five most recent searches', (tester) async {
    final client = FixtureDiscoveryClient();
    await tester.pumpWidget(StoreDiscoveryApp(apiClient: client));

    for (var index = 0; index < 6; index++) {
      await searchWithManualArea(tester, 'query-$index');
    }

    expect(find.text('query-0 · Taipei'), findsNothing);
    expect(find.text('query-1 · Taipei'), findsOneWidget);
    expect(find.text('query-5 · Taipei'), findsOneWidget);
  });

  testWidgets('does not retain precise-location searches', (tester) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(
        apiClient: FixtureDiscoveryClient(),
        locationService: FixtureLocationService(),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'cafe');
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsNothing);
  });

  testWidgets('adds, lists, and removes a favorite locally', (tester) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(apiClient: FixtureDiscoveryClient()),
    );

    await searchWithManualArea(tester, 'cafe');
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('North Gate Coffee'), findsNWidgets(2));
    expect(find.byTooltip('Remove from favorites'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Remove from favorites').first);
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsNothing);
    expect(find.byTooltip('Add to favorites'), findsOneWidget);
  });
}
