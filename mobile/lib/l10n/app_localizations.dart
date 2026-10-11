import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  static const delegate = AppLocalizationsDelegate();
  static const supportedLocales = [Locale('zh', 'TW'), Locale('en')];

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isChinese => locale.languageCode == 'zh';

  String get appTitle => isChinese ? '店家探索' : 'Store Discovery';
  String get intro => isChinese
      ? '找到附近實用的店家。'
      : 'Find a useful store nearby.';
  String get queryLabel =>
      isChinese ? '想找什麼？' : 'What are you looking for?';
  String get categoryLabel => isChinese ? '分類' : 'Category';
  String get radiusLabel => isChinese ? '搜尋半徑（公尺）' : 'Radius (m)';
  String get areaLabel => isChinese ? '區域' : 'Area';
  String get useLocation =>
      isChinese ? '使用我的位置' : 'Use my location';
  String get locating => isChinese ? '定位中…' : 'Locating…';
  String get search => isChinese ? '搜尋' : 'Search';
  String get searching => isChinese ? '搜尋中…' : 'Searching…';
  String get openNow => isChinese ? '目前營業中' : 'Open now';
  String get retry => isChinese ? '重試' : 'Retry';
  String get recentSearches => isChinese ? '最近搜尋' : 'Recent searches';
  String get clearRecentSearches =>
      isChinese ? '清除搜尋紀錄' : 'Clear recent searches';
  String get favorites => isChinese ? '收藏' : 'Favorites';
  String favoriteAction(bool isFavorite) => isFavorite
      ? (isChinese ? '取消收藏' : 'Remove from favorites')
      : (isChinese ? '加入收藏' : 'Add to favorites');
  String get noStores => isChinese ? '找不到店家。' : 'No stores found.';
  String get distanceUnknown => isChinese ? '距離未知' : 'Distance unknown';
  String get storeDetails => isChinese ? '店家詳細資料' : 'Store details';
  String get shareStore => isChinese ? '分享店家' : 'Share store';
  String get unableShareStore =>
      isChinese ? '無法分享店家連結。' : 'Unable to share the store link.';
  String get invalidStoreLink =>
      isChinese ? '店家連結無效。' : 'This store link is invalid.';
  String get storeLinkUnavailable => isChinese
      ? '目前無法開啟店家連結。'
      : 'This store link is unavailable right now.';
  String get searchNotConfigured =>
      isChinese ? '搜尋尚未設定。' : 'Search is not configured.';
  String get enterQueryAndArea => isChinese
      ? '請輸入需求和區域，或使用目前位置。'
      : 'Enter what you need and an area, or use your location.';
  String get enterValidRadius => isChinese
      ? '搜尋半徑必須是 1 到 50000 公尺。'
      : 'Radius must be between 1 and 50000 meters.';
  String get radiusRequiresLocation => isChinese
      ? '搜尋半徑需要先使用目前位置。'
      : 'Use your current location before setting a radius.';
  String get locationNotConfigured => isChinese
      ? '定位尚未設定，請改輸入區域。'
      : 'Location is not configured. Enter an area instead.';
  String get usingDeviceLocation => isChinese
      ? '使用裝置位置搜尋。'
      : 'Using device location for search.';
  String get locationServicesDisabled => isChinese
      ? '定位服務已關閉，請輸入區域。'
      : 'Location services are disabled. Enter an area instead.';
  String get locationPermissionDenied => isChinese
      ? '定位權限遭拒，請輸入區域。'
      : 'Location permission denied. Enter an area instead.';
  String get locationPermissionDisabled => isChinese
      ? '定位權限已停用，請輸入區域。'
      : 'Location permission is disabled. Enter an area instead.';
  String get unableReadLocation => isChinese
      ? '無法取得裝置位置，請輸入區域。'
      : 'Unable to read device location. Enter an area instead.';
  String get unableReachDiscovery => isChinese
      ? '無法連線到探索服務。'
      : 'Unable to reach discovery service.';
  String get discoveryTimedOut => isChinese
      ? '探索服務逾時，請再試一次。'
      : 'The discovery service timed out. Try again.';
  String get noNetwork => isChinese
      ? '沒有網路連線，請檢查網路後再試一次。'
      : 'No network connection. Check your connection and try again.';
  String get discoveryUnavailable => isChinese
      ? '探索服務無法使用，請再試一次。'
      : 'The discovery service is unavailable. Try again.';
  String get invalidDiscoveryResponse => isChinese
      ? '探索服務回傳無效資料。'
      : 'The discovery service returned an invalid response.';
  String get unableLoadDetails => isChinese
      ? '無法載入店家詳細資料。'
      : 'Unable to load store details.';
  String get mapUnavailable => isChinese
      ? '沒有可用的座標，無法顯示地圖。'
      : 'Map unavailable because this store has no coordinates.';
  String storeMap(String name) => isChinese ? '$name 地圖' : '$name map';
  String get openNavigation => isChinese ? '開啟導航' : 'Open navigation';
  String get unableOpenNavigation => isChinese
      ? '無法開啟導航。'
      : 'Unable to open navigation.';
  String get openStoreDetails =>
      isChinese ? '開啟店家詳細資料' : 'Open store details';
  String get address => isChinese ? '地址' : 'Address';
  String get businessHours => isChinese ? '營業時間' : 'Business hours';
  String get phone => isChinese ? '電話' : 'Phone';
  String get website => isChinese ? '網站' : 'Website';
  String get navigationTarget =>
      isChinese ? '導航目標' : 'Navigation target';
  String get attribution => isChinese ? '資料來源' : 'Attribution';
  String get unknownValue => isChinese ? '未提供' : 'Not available';

  String meters(int value) => isChinese ? '$value 公尺' : '$value m';

  String openState(String value) => switch (value) {
        'open' => isChinese ? '營業中' : 'Open',
        'closed' => isChinese ? '已歇業' : 'Closed',
        'unknown' => isChinese ? '營業狀態未知' : 'Open state unknown',
        _ => value,
      };

  String resultLabel(
    String name,
    String categories,
    String distance,
    String openState,
  ) => isChinese
      ? '$name，$categories，$distance，$openState'
      : '$name, $categories, $distance, $openState';
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
