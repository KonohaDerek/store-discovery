# Tests

Cross-module test assets live here. The first executable backend integration test
lives with the API test project; mobile widget tests live under `mobile/test/`.

Initial strategy:
- domain/unit tests inside implementation modules
- provider adapter tests using fixtures/fakes
- API contract tests
- end-to-end smoke test for the core discovery flow

Live paid provider calls must not be required for the default test suite.
