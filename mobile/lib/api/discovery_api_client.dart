import 'dart:convert';
import 'dart:io';

class DiscoveryApiClient {
  const DiscoveryApiClient({required this.baseUri});

  final Uri baseUri;

  Future<DiscoveryResponse> discover({
    required String query,
    String? category,
    String? area,
  }) async {
    final parameters = <String, String>{'q': query};
    if (category != null && category.isNotEmpty) {
      parameters['category'] = category;
    }
    if (area != null && area.isNotEmpty) parameters['area'] = area;

    final uri = baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/stores/discover',
      queryParameters: parameters,
    );
    final httpClient = HttpClient();

    try {
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != HttpStatus.ok) {
        final error = json['error'] as Map<String, dynamic>?;
        throw DiscoveryApiException(
          error?['message'] as String? ?? 'Discovery request failed.',
        );
      }

      return DiscoveryResponse.fromJson(json);
    } finally {
      httpClient.close();
    }
  }

  Future<StoreDetail> getStore(String storeId) async {
    final path = '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/stores/'
        '${Uri.encodeComponent(storeId)}';
    final httpClient = HttpClient();

    try {
      final request = await httpClient.getUrl(baseUri.replace(path: path));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != HttpStatus.ok) {
        final error = json['error'] as Map<String, dynamic>?;
        throw DiscoveryApiException(
          error?['message'] as String? ?? 'Store detail request failed.',
        );
      }

      return StoreDetail.fromJson(json);
    } finally {
      httpClient.close();
    }
  }
}

class DiscoveryApiException implements Exception {
  const DiscoveryApiException(this.message);

  final String message;
}

class DiscoveryResponse {
  const DiscoveryResponse({required this.items, this.nextCursor});

  factory DiscoveryResponse.fromJson(Map<String, dynamic> json) {
    return DiscoveryResponse(
      items: (json['items'] as List<dynamic>)
          .map((item) => StoreSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<StoreSummary> items;
  final String? nextCursor;
}

class StoreSummary {
  const StoreSummary({
    required this.storeId,
    required this.name,
    required this.categories,
    required this.distanceMeters,
    required this.addressSummary,
    required this.openState,
  });

  factory StoreSummary.fromJson(Map<String, dynamic> json) {
    return StoreSummary(
      storeId: json['storeId'] as String,
      name: json['name'] as String,
      categories: (json['categories'] as List<dynamic>).cast<String>(),
      distanceMeters: json['distanceMeters'] as int?,
      addressSummary: json['addressSummary'] as String,
      openState: json['openState'] as String,
    );
  }

  final String storeId;
  final String name;
  final List<String> categories;
  final int? distanceMeters;
  final String addressSummary;
  final String openState;
}

class StoreDetail {
  const StoreDetail({
    required this.name,
    required this.address,
    required this.businessHours,
    required this.openState,
    this.phone,
    this.website,
    this.navigationTarget,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    return StoreDetail(
      name: json['name'] as String,
      address: json['fullAddress'] as String,
      businessHours: (json['businessHours'] as List<dynamic>).cast<String>(),
      openState: json['openState'] as String,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      navigationTarget: json['navigationTarget'] as String?,
    );
  }

  final String name;
  final String address;
  final List<String> businessHours;
  final String openState;
  final String? phone;
  final String? website;
  final String? navigationTarget;
}
