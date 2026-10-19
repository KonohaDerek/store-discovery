import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/api/discovery_api_client.dart';
import 'package:store_discovery/deep_links/store_deep_link.dart';
import 'package:store_discovery/deep_links/store_link_source.dart';
import 'package:store_discovery/main.dart';
import 'package:store_discovery/share/store_share_service.dart';

class FakeStoreLinkSource implements StoreLinkSource {
  FakeStoreLinkSource(this.value);

  final Uri? value;

  @override
  Stream<Uri> get linkStream => const Stream<Uri>.empty();

  @override
  Future<Uri?> initialLink() async => value;
}

class FakeStoreApiClient extends DiscoveryApiClient {
  FakeStoreApiClient() : super(baseUri: Uri.parse('http://localhost'));

  @override
  Future<StoreDetail> getStore(String storeId) async => const StoreDetail(
        name: 'North Gate Coffee',
        address: 'Taipei',
        businessHours: ['09:00–18:00'],
        openState: 'open',
      );
}

class RecordingShareService implements StoreShareService {
  String? storeId;

  @override
  Future<void> shareStore(String value) async {
    storeId = value;
  }
}

void main() {
  testWidgets('opens a store detail from an initial deep link', (tester) async {
    final shareService = RecordingShareService();
    await tester.pumpWidget(
      StoreDiscoveryApp(
        locale: const Locale('en'),
        apiClient: FakeStoreApiClient(),
        shareService: shareService,
        linkSource: FakeStoreLinkSource(
          StoreDeepLink.forStore('sample-cafe-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('North Gate Coffee'), findsOneWidget);
    expect(find.byTooltip('Share store'), findsOneWidget);

    await tester.tap(find.byTooltip('Share store'));
    await tester.pump();
    expect(shareService.storeId, 'sample-cafe-1');
  });

  testWidgets('shows an error for an invalid initial deep link', (tester) async {
    await tester.pumpWidget(
      StoreDiscoveryApp(
        locale: const Locale('en'),
        apiClient: FakeStoreApiClient(),
        linkSource: FakeStoreLinkSource(
          Uri.parse('https://example.com/store'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This store link is invalid.'), findsOneWidget);
  });
}
