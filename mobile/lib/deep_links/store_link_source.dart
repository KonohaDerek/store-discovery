import 'package:app_links/app_links.dart';

abstract interface class StoreLinkSource {
  Stream<Uri> get linkStream;

  Future<Uri?> initialLink();
}

class AppLinksStoreLinkSource implements StoreLinkSource {
  AppLinksStoreLinkSource({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get linkStream => _appLinks.uriLinkStream;

  @override
  Future<Uri?> initialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (_) {
      // A platform runner without link configuration should not block startup.
      return null;
    }
  }
}
