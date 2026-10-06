import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/api/discovery_api_client.dart';
import 'package:store_discovery/config/app_config.dart';

void main() {
  test('builds the API client from environment configuration', () {
    const config = AppConfig(apiBaseUrl: 'https://api.example.test/api/v1');
    final client = DiscoveryApiClient(baseUri: Uri.parse('https://api.example.test/api/v1'));

    expect(config.apiUri, client.baseUri);
  });
}
