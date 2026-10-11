import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/navigation/navigation_service.dart';

void main() {
  test('opens a valid navigation URL through the injected launcher', () async {
    Uri? opened;
    final service = PlatformNavigationService(
      launcher: (uri) async {
        opened = uri;
        return true;
      },
    );

    final result = await service.open('https://maps.google.com/?q=25.04,121.51');

    expect(result, isTrue);
    expect(opened?.host, 'maps.google.com');
  });

  test('rejects invalid or unsupported navigation targets safely', () async {
    var attempts = 0;
    final service = PlatformNavigationService(
      launcher: (_) async {
        attempts++;
        return true;
      },
    );

    expect(await service.open('not a URL'), isFalse);
    expect(await service.open('javascript:alert(1)'), isFalse);
    expect(attempts, 0);
  });
}
