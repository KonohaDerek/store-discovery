import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/main.dart';

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
}
