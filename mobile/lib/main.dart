import 'package:flutter/material.dart';

import 'api/discovery_api_client.dart';
import 'config/app_config.dart';

void main() {
  runApp(StoreDiscoveryApp(
    apiClient: DiscoveryApiClient(baseUri: AppConfig.fromEnvironment().apiUri),
  ));
}

class StoreDiscoveryApp extends StatelessWidget {
  const StoreDiscoveryApp({super.key, this.apiClient});

  final DiscoveryApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Discovery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: DiscoveryHomePage(apiClient: apiClient),
    );
  }
}

class DiscoveryHomePage extends StatefulWidget {
  const DiscoveryHomePage({super.key, this.apiClient});

  final DiscoveryApiClient? apiClient;

  @override
  State<DiscoveryHomePage> createState() => _DiscoveryHomePageState();
}

class _DiscoveryHomePageState extends State<DiscoveryHomePage> {
  final queryController = TextEditingController();
  final areaController = TextEditingController();
  List<StoreSummary> results = const [];
  String? errorMessage;
  bool isLoading = false;
  bool hasSearched = false;

  @override
  void dispose() {
    queryController.dispose();
    areaController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = queryController.text.trim();
    final area = areaController.text.trim();
    if (widget.apiClient == null) {
      setState(() => errorMessage = 'Search is not configured.');
      return;
    }
    if (query.isEmpty || area.isEmpty) {
      setState(
        () => errorMessage = 'Enter what you need and an area to search.',
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      results = const [];
    });

    try {
      final response = await widget.apiClient!.discover(
        query: query,
        area: area,
      );
      if (!mounted) return;
      setState(() {
        results = response.items;
        hasSearched = true;
      });
    } on DiscoveryApiException catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Unable to reach discovery service.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Discovery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Find a useful store nearby.'),
          const SizedBox(height: 16),
          TextField(
            controller: queryController,
            decoration: const InputDecoration(
              labelText: 'What are you looking for?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: areaController,
            decoration: const InputDecoration(
              labelText: 'Area',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isLoading ? null : search,
            child: Text(isLoading ? 'Searching…' : 'Search'),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.red.shade700)),
          ],
          ...results.map(
            (store) => Card(
              child: ListTile(
                title: Text(store.name),
                subtitle: Text('${store.addressSummary}\n${store.openState}'),
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
          ),
          if (hasSearched && results.isEmpty && errorMessage == null)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('No stores found.'),
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
  late final Future<StoreDetail> detailFuture;

  @override
  void initState() {
    super.initState();
    detailFuture = widget.apiClient.getStore(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store details')),
      body: FutureBuilder<StoreDetail>(
        future: detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Center(
              child: Text(
                error is DiscoveryApiException
                    ? error.message
                    : 'Unable to load store details.',
              ),
            );
          }

          final store = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                store.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(store.openState),
              const SizedBox(height: 12),
              Text(store.address),
              const SizedBox(height: 12),
              Text(store.businessHours.join('\n')),
              if (store.phone != null) Text(store.phone!),
              if (store.website != null) Text(store.website!),
            ],
          );
        },
      ),
    );
  }
}
