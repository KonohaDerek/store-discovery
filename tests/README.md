# Tests

Cross-module test assets live here.

Initial strategy:
- domain/unit tests inside implementation modules
- provider adapter tests using fixtures/fakes
- API contract tests
- end-to-end smoke test for the core discovery flow

Live paid provider calls must not be required for the default test suite.
