import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/api/discovery_api_client.dart';
import 'package:store_discovery/main.dart';

class RetryClient extends DiscoveryApiClient {
  RetryClient() : super(baseUri: Uri.parse('http://localhost'));

  var attempts = 0;
  var shouldFail = true;

  @override
  Future<DiscoveryResponse> discover({
    required String query,
    String? category,
    String? area,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    bool openNow = false,
  }) async {
    attempts++;
    if (shouldFail) {
      throw const DiscoveryApiException(
        DiscoveryFailure.network,
        'No network connection. Check your connection and try again.',
      );
    }

    return const DiscoveryResponse(
      items: [
        StoreSummary(
          storeId: 'sample-cafe-1',
          name: 'North Gate Coffee',
          categories: ['food.cafe'],
          distanceMeters: 350,
          addressSummary: 'Taipei',
          openState: 'open',
        ),
      ],
    );
  }
}

void main() {
  testWidgets('renders the discovery shell', (tester) async {
    await tester.pumpWidget(const StoreDiscoveryApp());

    expect(find.text('Store Discovery'), findsOneWidget);
    expect(find.text('Find a useful store nearby.'), findsOneWidget);
    expect(find.text('What are you looking for?'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('offers retry after a network failure', (tester) async {
    final client = RetryClient();
    await tester.pumpWidget(StoreDiscoveryApp(apiClient: client));

    await tester.enterText(find.byType(TextField).first, 'cafe');
    await tester.enterText(find.byType(TextField).last, 'Taipei');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(
      find.text('No network connection. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    client.shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('North Gate Coffee'), findsOneWidget);
    expect(client.attempts, 2);
  });
}
