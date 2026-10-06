class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  const AppConfig.fromEnvironment()
      : apiBaseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:5000/api/v1',
        );

  final String apiBaseUrl;

  Uri get apiUri => Uri.parse(apiBaseUrl);
}
