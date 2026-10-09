import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/api/discovery_api_client.dart';
import 'package:store_discovery/main.dart';

class FixtureDiscoveryClient extends DiscoveryApiClient {
  FixtureDiscoveryClient({this.failDiscovery = false})
      : super(baseUri: Uri.parse('http://fixture'));

  final bool failDiscovery;

  @override
  Future<DiscoveryResponse> discover({
    required String query,
    String? category,
    String? area,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
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
      navigationTarget: 'https://maps.google.com/',
    );
  }
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
}
