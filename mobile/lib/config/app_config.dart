class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  const AppConfig.fromEnvironment()
      : apiBaseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: '',
        );

  final String apiBaseUrl;

  bool get isConfigured => apiBaseUrl.isNotEmpty;

  Uri get apiUri => Uri.parse(apiBaseUrl);
}
