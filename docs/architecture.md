# Architecture

## Principles

- Mobile-first, backend-mediated provider access.
- Provider-neutral domain contracts.
- DevContainer-first development.
- Specification before implementation.
- Start as a modular monolith; split services only when operational evidence requires it.
- No unnecessary database dependency in the read-only discovery vertical slice.

## Logical architecture

```text
iOS / Android
     |
     v
Store Discovery API
     |
     +--> Discovery Application Layer
     |       |
     |       +--> Ranking / normalization
     |
     +--> Place Provider Interface
              |
              +--> Provider Adapter A
              +--> Future Provider Adapter B
```

Optional persistence/caching sits behind interfaces and must not leak provider-specific schemas into mobile contracts.

## Initial modules

### mobile
Search/discovery UI, permission handling, result list, store detail, navigation hand-off.

### backend
HTTP API, validation, discovery use cases, provider adapters, normalization, observability.

### tests
Contract, integration and end-to-end tests that span modules.

## Architecture decisions pending

| Decision | Status |
|---|---|
| Mobile framework | Pending |
| Backend runtime | Pending |
| External places provider | Pending |
| Map provider | Pending |
| Database | Deferred until persistence use case |
| Authentication | Deferred pending MVP account requirement |

## Security baseline

- Provider keys are server-side only where licensing permits.
- Secrets use environment/secret injection.
- Validate all external input.
- Apply request timeout/retry policies at provider boundary.
- Avoid storing precise location unless a feature explicitly requires it.
