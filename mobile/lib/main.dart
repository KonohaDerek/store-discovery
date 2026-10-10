import 'package:flutter/material.dart';

import 'api/discovery_api_client.dart';
import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'location/location_service.dart';

class RecentSearch {
  const RecentSearch({
    required this.query,
    required this.category,
    required this.area,
  });

  final String query;
  final String category;
  final String area;

  String get label => [query, category, area]
      .where((value) => value.isNotEmpty)
      .join(' · ');

  bool matches(String otherQuery, String otherCategory, String otherArea) =>
      query == otherQuery &&
      category == otherCategory &&
      area == otherArea;
}

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(StoreDiscoveryApp(
    apiClient: config.isConfigured
        ? DiscoveryApiClient(baseUri: config.apiUri)
        : null,
    locationService: const DeviceLocationService(),
  ));
}

class StoreDiscoveryApp extends StatelessWidget {
  const StoreDiscoveryApp({
    super.key,
    this.apiClient,
    this.locationService,
    this.locale,
  });

  final DiscoveryApiClient? apiClient;
  final LocationService? locationService;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, _) =>
          locale?.languageCode == 'zh'
              ? const Locale('zh', 'TW')
              : const Locale('en'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: DiscoveryHomePage(
        apiClient: apiClient,
        locationService: locationService,
      ),
    );
  }
}

class DiscoveryHomePage extends StatefulWidget {
  const DiscoveryHomePage({
    super.key,
    this.apiClient,
    this.locationService,
  });

  final DiscoveryApiClient? apiClient;
  final LocationService? locationService;

  @override
  State<DiscoveryHomePage> createState() => _DiscoveryHomePageState();
}

class _DiscoveryHomePageState extends State<DiscoveryHomePage> {
  static const maxRecentSearches = 5;

  final queryController = TextEditingController();
  final categoryController = TextEditingController();
  final areaController = TextEditingController();
  final favoriteStores = <StoreSummary>[];
  final recentSearches = <RecentSearch>[];
  List<StoreSummary> results = const [];
  String? errorMessage;
  String? locationMessage;
  LocationPoint? location;
  bool isLoading = false;
  bool isLocating = false;
  bool hasSearched = false;

  @override
  void dispose() {
    queryController.dispose();
    categoryController.dispose();
    areaController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final l10n = AppLocalizations.of(context);
    final query = queryController.text.trim();
    final category = categoryController.text.trim();
    final area = areaController.text.trim();
    if (widget.apiClient == null) {
      setState(() => errorMessage = l10n.searchNotConfigured);
      return;
    }
    if ((query.isEmpty && category.isEmpty) ||
        (area.isEmpty && location == null)) {
      setState(() => errorMessage = l10n.enterQueryAndArea);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      results = const [];
      hasSearched = true;
    });

    try {
      final response = await widget.apiClient!.discover(
        query: query,
        category: category.isEmpty ? null : category,
        area: area.isEmpty ? null : area,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
      if (!mounted) return;
      setState(() {
        rememberRecentSearch(query, category, area);
        results = response.items;
      });
    } on DiscoveryApiException catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = discoveryErrorMessage(error, l10n));
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = l10n.unableReachDiscovery);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void rememberRecentSearch(String query, String category, String area) {
    if (area.isEmpty) return;
    recentSearches.removeWhere(
      (recent) => recent.matches(query, category, area),
    );
    recentSearches.insert(
      0,
      RecentSearch(query: query, category: category, area: area),
    );
    if (recentSearches.length > maxRecentSearches) {
      recentSearches.removeLast();
    }
  }

  Future<void> repeatRecentSearch(RecentSearch recent) async {
    queryController.text = recent.query;
    categoryController.text = recent.category;
    areaController.text = recent.area;
    location = null;
    locationMessage = null;
    await search();
  }

  void clearRecentSearches() {
    setState(recentSearches.clear);
  }

  bool isFavorite(StoreSummary store) =>
      favoriteStores.any((favorite) => favorite.storeId == store.storeId);

  void toggleFavorite(StoreSummary store) {
    setState(() {
      final index = favoriteStores.indexWhere(
        (favorite) => favorite.storeId == store.storeId,
      );
      if (index >= 0) {
        favoriteStores.removeAt(index);
      } else {
        favoriteStores.insert(0, store);
      }
    });
  }

  Widget storeTile(StoreSummary store, AppLocalizations l10n) {
    final categories = store.categories.join(', ');
    final distance = store.distanceMeters == null
        ? l10n.distanceUnknown
        : l10n.meters(store.distanceMeters!);
    final openState = l10n.openState(store.openState);
    final favorite = isFavorite(store);
    return Semantics(
      button: true,
      label: l10n.resultLabel(
        store.name,
        categories,
        distance,
        openState,
      ),
      hint: l10n.openStoreDetails,
      child: Card(
        child: ListTile(
          title: Text(store.name),
          subtitle: Text(
            '$categories · $distance\n'
            '${store.addressSummary}\n$openState',
          ),
          trailing: IconButton(
            icon: Icon(favorite ? Icons.star : Icons.star_border),
            tooltip: l10n.favoriteAction(favorite),
            onPressed: () => toggleFavorite(store),
          ),
          onTap: widget.apiClient == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StoreDetailPage(
                        apiClient: widget.apiClient!,
                        storeId: store.storeId,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    final service = widget.locationService;
    if (service == null) {
      setState(() => locationMessage = l10n.locationNotConfigured);
      return;
    }

    setState(() {
      isLocating = true;
      locationMessage = null;
      errorMessage = null;
    });

    try {
      final current = await service.currentLocation();
      if (!mounted) return;
      setState(() {
        location = current;
        areaController.clear();
        locationMessage = l10n.usingDeviceLocation;
      });
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() {
        location = null;
        locationMessage = locationErrorMessage(error, l10n);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        location = null;
        locationMessage = l10n.unableReadLocation;
      });
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(header: true, child: Text(l10n.intro)),
          const SizedBox(height: 16),
          TextField(
            controller: queryController,
            decoration: InputDecoration(
              labelText: l10n.queryLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: categoryController,
            decoration: InputDecoration(
              labelText: l10n.categoryLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: areaController,
            decoration: InputDecoration(
              labelText: l10n.areaLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLocating ? null : useCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: Text(isLocating ? l10n.locating : l10n.useLocation),
          ),
          if (locationMessage != null) ...[
            const SizedBox(height: 8),
            Semantics(liveRegion: true, child: Text(locationMessage!)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isLoading || isLocating ? null : search,
            child: Text(isLoading ? l10n.searching : l10n.search),
          ),
          if (recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.recentSearches),
                ),
                TextButton(
                  onPressed: clearRecentSearches,
                  child: Text(l10n.clearRecentSearches),
                ),
              ],
            ),
            ...recentSearches.map(
              (recent) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(recent.label),
                onTap: () => repeatRecentSearch(recent),
              ),
            ),
          ],
          if (favoriteStores.isNotEmpty) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(l10n.favorites),
            ),
            ...favoriteStores.map((store) => storeTile(store, l10n)),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isLoading ? null : search,
              child: Text(l10n.retry),
            ),
          ],
          ...results.map((store) => storeTile(store, l10n)),
          if (hasSearched && results.isEmpty && errorMessage == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(l10n.noStores),
            ),
        ],
      ),
    );
  }
}

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({
    super.key,
    required this.apiClient,
    required this.storeId,
  });

  final DiscoveryApiClient apiClient;
  final String storeId;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late Future<StoreDetail> detailFuture;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  void loadDetail() {
    detailFuture = widget.apiClient.getStore(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storeDetails)),
      body: FutureBuilder<StoreDetail>(
        future: detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is DiscoveryApiException
                ? discoveryErrorMessage(error, l10n)
                : l10n.unableLoadDetails;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => loadDetail()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final store = snapshot.data!;
          final address = store.address ?? l10n.unknownValue;
          final businessHours = store.businessHours.isEmpty
              ? l10n.unknownValue
              : store.businessHours.join('\n');
          final phone = store.phone ?? l10n.unknownValue;
          final website = store.website ?? l10n.unknownValue;
          final navigationTarget =
              store.navigationTarget ?? l10n.unknownValue;
          final attribution = store.attribution ?? l10n.unknownValue;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                store.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.openState(store.openState)),
              const SizedBox(height: 12),
              Semantics(
                label: '${l10n.address}: $address',
                child: Text(address),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: '${l10n.businessHours}: $businessHours',
                child: Text(businessHours),
              ),
              Semantics(
                label: '${l10n.phone}: $phone',
                child: Text(phone),
              ),
              Semantics(
                label: '${l10n.website}: $website',
                child: Text(website),
              ),
              Semantics(
                label: '${l10n.navigationTarget}: $navigationTarget',
                child: Text(navigationTarget),
              ),
              Semantics(
                label: '${l10n.attribution}: $attribution',
                child: Text(attribution),
              ),
            ],
          );
        },
      ),
    );
  }
}

String discoveryErrorMessage(
  DiscoveryApiException error,
  AppLocalizations l10n,
) => switch (error.failure) {
      DiscoveryFailure.timeout => l10n.discoveryTimedOut,
      DiscoveryFailure.network => l10n.noNetwork,
      DiscoveryFailure.unavailable => l10n.discoveryUnavailable,
      DiscoveryFailure.invalidResponse => l10n.invalidDiscoveryResponse,
    };

String locationErrorMessage(
  LocationException error,
  AppLocalizations l10n,
) => switch (error.failure) {
      LocationFailure.servicesDisabled => l10n.locationServicesDisabled,
      LocationFailure.permissionDenied => l10n.locationPermissionDenied,
      LocationFailure.permissionDeniedForever =>
        l10n.locationPermissionDisabled,
      LocationFailure.unknown => l10n.unableReadLocation,
    };
