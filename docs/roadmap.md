# Store Discovery Roadmap

GitHub Issues are the source of truth for execution. This document defines ordering and phase gates.

## Current implementation status

- #16 Mobile scaffold: source and widget-test contract implemented; DevContainer
  platform generation and Android build verification remain.
- #17 Backend scaffold: .NET 10 API host, live/ready health endpoints,
  configuration validation, correlation logging, and integration tests implemented.
- Discovery vertical slice: versioned discovery endpoint, deterministic sample
  provider, and Flutter search/results shell implemented; Google Places API
  (New) adapter is now available behind the provider-neutral interface.
- #4 Location input: explicit device-location action with permission/denied
  fallback to manual area; platform permission declarations remain in mobile
  runner setup.
- #19 Normalized filters and ranking: category filtering, coordinate-relative
  distance/radius behavior, and deterministic open-state ranking implemented.
- #21 Mobile API resilience: timeout/network/unavailable response mapping and
  retry actions implemented for discovery and store detail.
- #8 Core discovery smoke test: deterministic mobile success and provider-failure
  flows cover manual-area search, results, and store detail.
- #22 Accessibility and localization: core strings use a Traditional Chinese
  baseline with English fallback, and search/detail states expose semantics.
- #7 Store detail: mobile parsing and presentation now cover navigation target,
  attribution, and explicit unknown values for missing provider fields.
- #20 Map presentation and navigation hand-off: mobile detail pages render a
  Google Maps view for valid coordinates, safely fall back when coordinates are
  unavailable, and open the provider navigation target externally. Native
  runner API-key registration remains part of the separate runner setup.
- #6 Discovery search/results: keyword or category input, API query, ranked
  result presentation, detail navigation, and state coverage implemented.
- #12 CI quality gates: workflow implemented after the #16/#17 source checks;
  required-check enforcement still belongs to GitHub branch protection settings.
- #28 Recent searches: session-only manual search history with a five-item
  retention limit, repeat action, clear action, and no precise location storage.
- #27 Favorites: session-local favorite / unfavorite using the normalized
  `storeId`, with a favorites list and offline-safe local actions.
- #23 Security and abuse controls: validated API input, normalized safe errors,
  backend-only provider secrets, native-client CORS decision, and a fixed-window
  public API rate limit with integration coverage.
- #24/#25 Delivery verification: CI builds and validates the backend container,
  publishes immutable GHCR tags, generates the Android runner in CI, and
  attaches an internal debug APK with checksum to a GitHub Release.
- #42 Advanced discovery filters: category, open-now, and location-based radius
  filters with API validation, normalized provider capability behavior, and tests.
- #41 Share links and deep links: canonical store URI, platform share action, and
  installed-app link handling are implemented; native runner registration and
  device verification remain part of the separate mobile runner setup.

## Phase 0 — Foundation

### Architecture decisions — do first
- #1 Select mobile framework for iOS and Android
- #2 Select backend runtime and initial API architecture
- #3 Select places/store data and map providers

### Product / engineering foundation
- #9 Product taxonomy and normalized store categories
- #10 API/domain contracts and compatibility policy
- #11 Repository engineering standards
- #12 CI quality gates
- #13 Secrets and environment configuration
- #14 Observability baseline
- #15 Privacy, location-data and retention policy

**Gate:** implementation stack, provider constraints, contracts, privacy baseline and engineering workflow are sufficiently defined to scaffold production code.

## Phase 1 — MVP

### Scaffolding and core vertical slice
- #16 Scaffold selected mobile application
- #17 Scaffold backend service and health endpoints
- #18 Implement first real places provider adapter
- #4 Location input and permission fallback
- #5 Store discovery API with provider abstraction
- #19 Normalized filters and discovery ranking
- #6 Discovery search and results screen
- #7 Store detail API and mobile screen
- #20 Map presentation and navigation hand-off

### Reliability and release engineering
- #21 Mobile API error/loading/offline resilience
- #22 Accessibility and localization baseline
- #23 Security review and API abuse controls
- #24 Deployment environments and backend delivery
- #25 Internal mobile distribution
- #8 Core discovery E2E smoke test
- #26 MVP release readiness and acceptance

**MVP outcome:** location/area → discovery intent → ranked store results → store detail → navigation, with deterministic tests and a real provider integration.

## Phase 2 — Personal Utility

- #27 Favorites
- #28 Recent searches
- #41 Share links and deep links
- #42 Advanced discovery filters
- #43 Provider-compliant caching
- #44 Decide account/authentication model
- #45 Sync user-owned data across devices (only if accounts are accepted)

**Gate:** only add accounts when cross-device/user-owned data provides enough value to justify identity lifecycle and privacy complexity.

## Phase 3 — Intelligent Discovery

- #46 Preference model
- #47 Preference-aware ranking
- #48 Natural-language discovery intent
- #49 Recommendation explanations
- #50 Multi-provider strategy evaluation

AI features must consume normalized factual store data. They must not invent store attributes or hide uncertainty.

## Cross-cutting quality

- #51 Product analytics and MVP success metrics
- #52 Performance budgets and load-test baseline
- #53 Dependency, license and supply-chain checks

These can begin during Phase 0/1 and become release gates as appropriate.

## Release

- #54 Public beta readiness

## Explicitly deferred

Advanced Hermes orchestration, parallel workers, automatic retries, and OpenAB are deferred until the single-worker POC is stable. The first GitHub → Hermes → MacBook → DevContainer → Codex → PR path is tracked as `MVP-00 Foundation` in [agent-workflow.md](agent-workflow.md).

## Recommended execution order

```text
#1 + #2 + #3
      ↓
#9–#15
      ↓
#16 + #17
      ↓
#4 + #5 + #18 + #19
      ↓
#6 + #7 + #20
      ↓
#8 + #21–#26
      ↓
MVP accepted
      ↓
#27–#45
      ↓
#46–#50
      ↓
#54 Public Beta
```
