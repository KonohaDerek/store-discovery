# Architecture

## Accepted technology decisions

| Area | Decision |
|---|---|
| Mobile | Flutter 3.47.x / Dart |
| Backend | .NET 10 LTS / ASP.NET Core |
| Places | Google Places API (New), backend-mediated |
| Maps | Google Maps SDK for iOS and Android |
| API | REST, versioned under `/api/v1` |
| Architecture | Modular monolith + provider adapters |
| Database | Deferred until a persistence use case exists |
| Observability | OpenTelemetry baseline |
| Authentication | Deferred pending Phase 2 account decision |

See GitHub Issues #1, #2 and #3 for decision rationale and alternatives.

## Principles

- Mobile-first, backend-mediated provider access.
- Provider-neutral domain contracts.
- DevContainer-first development.
- Specification before implementation.
- Start as a modular monolith; split services only when operational evidence requires it.
- No unnecessary database dependency in the read-only discovery vertical slice.
- Never mirror an external place provider's dataset unless its license explicitly permits it.

## Logical architecture

```text
Flutter iOS / Android
        |
        | REST /api/v1
        v
ASP.NET Core Store Discovery API
        |
        +--> Application / Discovery
        |       |
        |       +--> Ranking / normalization
        |
        +--> IPlaceProvider
                |
                +--> GooglePlacesProvider (MVP)
                +--> Future provider adapter
```

## Mobile

Flutter owns:
- discovery/search UI
- device location permission
- manual-area fallback
- result/detail presentation
- Google Maps presentation
- navigation hand-off
- local ephemeral state

Platform-specific integrations should use maintained Flutter plugins first, then platform channels/native code when justified.

### DevContainer exception for iOS

Flutter/Dart and Android project toolchains should be pinned in the DevContainer. Apple requires Xcode/macOS for iOS build, simulator, codesigning and distribution; Xcode is therefore treated as required host platform tooling rather than a project SDK.

## Backend modules

### API
HTTP endpoints, transport contracts, validation, error mapping.

### Application
Discovery/detail use cases and orchestration.

### Domain
Provider-neutral StoreSummary, StoreDetail, discovery/filter concepts.

### Infrastructure
Google Places adapter, configuration, resilience policies and future persistence/cache implementations.

### Observability
OpenTelemetry logs/metrics/traces, correlation IDs and provider latency/error metrics.

## Provider policy

Google Places API (New) is the MVP source. Mobile does not receive privileged provider credentials.

Only request fields needed for the current use case. Do not persist arbitrary Places content. Provider identifiers may be retained where terms permit; Google Place IDs are specifically exempt from caching restrictions.

The application contract must not expose Google-specific schemas as its domain model.

## Security baseline

- Provider keys are server-side where applicable.
- Secrets use environment/secret injection.
- Validate all external input.
- Apply timeout/retry/circuit behavior at provider boundaries.
- Avoid storing precise user location by default.
- Redact location/secrets from logs where not operationally required.
