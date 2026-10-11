import 'package:url_launcher/url_launcher.dart';

typedef NavigationLauncher = Future<bool> Function(Uri uri);

abstract interface class NavigationService {
  Future<bool> open(String target);
}

class PlatformNavigationService implements NavigationService {
  PlatformNavigationService({NavigationLauncher? launcher})
      : _launcher = launcher ?? _launchExternally;

  final NavigationLauncher _launcher;

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<bool> open(String target) {
    final uri = Uri.tryParse(target);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return Future.value(false);
    }
    return _launcher(uri);
  }
}
