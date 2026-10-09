import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/location/location_service.dart';
import 'package:store_discovery/main.dart';

class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  final Object result;

  @override
  Future<LocationPoint> currentLocation() async {
    if (result is LocationException) {
      throw result;
    }
    return result as LocationPoint;
  }
}

void main() {
  testWidgets('uses device location without requiring an area', (tester) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(
        locationService: FakeLocationService(
          const LocationPoint(latitude: 25.0478, longitude: 121.5170),
        ),
      ),
    );

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();

    expect(find.text('Using device location for search.'), findsOneWidget);
  });

  testWidgets('shows the manual-area fallback after permission denial', (
    tester,
  ) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(
        locationService: FakeLocationService(
          const LocationException(
            LocationFailure.permissionDenied,
            'Location permission denied. Enter an area instead.',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();

    expect(
      find.text('Location permission denied. Enter an area instead.'),
      findsOneWidget,
    );
    expect(find.text('Area'), findsOneWidget);
  });
}
