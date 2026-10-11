class StoreDeepLink {
  const StoreDeepLink._();

  static const scheme = 'store-discovery';
  static const host = 'store';

  static Uri forStore(String storeId) {
    final normalizedId = storeId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(storeId, 'storeId', 'must not be empty');
    }

    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: [normalizedId],
    );
  }

  static String? storeIdFrom(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    if (uri.queryParameters.isNotEmpty || uri.fragment.isNotEmpty) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length != 1 || segments.single.trim().isEmpty) return null;
    return segments.single;
  }
}
