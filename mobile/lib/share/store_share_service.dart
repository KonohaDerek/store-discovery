import 'package:share_plus/share_plus.dart';

import '../deep_links/store_deep_link.dart';

abstract interface class StoreShareService {
  Future<void> shareStore(String storeId);
}

class PlatformStoreShareService implements StoreShareService {
  const PlatformStoreShareService();

  @override
  Future<void> shareStore(String storeId) async {
    await SharePlus.instance.share(
      ShareParams(uri: StoreDeepLink.forStore(storeId)),
    );
  }
}
