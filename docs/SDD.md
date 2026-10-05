# Store Discovery — Software Design Document

Status: Draft  
Phase: MVP definition

## 1. Problem

Finding a useful store nearby often requires switching between map search, search engines, social recommendations, and individual store pages. Store Discovery should provide a focused mobile experience that starts from user intent and location and returns actionable store choices.

## 2. MVP objective

Prove the core discovery loop:

1. Obtain a location with explicit user permission, or accept a manually selected area.
2. Accept a keyword or category.
3. Query the backend discovery API.
4. Return a ranked list of stores.
5. Open a store detail view containing enough information for the user to decide whether to visit.

## 3. MVP user stories

### US-01 Discover nearby stores
As a user, I want to search for a type of store near a location so that I can quickly find relevant choices.

Acceptance criteria:
- Search works with a keyword/category.
- Location can come from device permission or manual input.
- Results expose name, category, approximate distance, and open-state when available.
- Empty/error/loading states are explicit.

### US-02 Inspect a store
As a user, I want to open a result and inspect store details before deciding to visit.

Acceptance criteria:
- Detail identifies the store and address.
- Shows provider-backed business hours/open-state when available.
- Shows contact/website/map-navigation fields when available.
- Missing provider data is represented as unknown rather than invented.

### US-03 Protect location privacy
As a user, I want control over location access.

Acceptance criteria:
- App requests location only when required.
- Denying permission does not block manual-area discovery.
- Raw location is not persisted by default.

## 4. Non-functional requirements

- Mobile clients: iOS and Android.
- Project toolchains run in DevContainer; Mac host remains SDK-light.
- Backend is the boundary to external place/store providers; mobile must not embed privileged provider secrets.
- Provider integration must be abstracted to allow replacement or multiple providers.
- APIs must use versioned contracts.
- Structured logs and request correlation are required from the first backend vertical slice.
- Tests must not depend on paid/live provider calls by default.

## 5. Proposed system boundaries

- Mobile App: presentation, device location permission, search UX, local ephemeral state.
- Backend API: discovery orchestration, validation, ranking, provider abstraction, normalization.
- Place Provider Adapter: external place/store data integration.
- Persistence: initially optional for core discovery; introduced for user-owned data and caching when justified.
- Observability: logs/metrics/traces at service boundaries.

## 6. Core domain model

### DiscoveryQuery
- query
- category
- latitude/longitude or area
- radius
- locale
- pagination cursor

### StoreSummary
- storeId
- name
- categories
- coordinates
- address summary
- distance
- openState
- source

### StoreDetail
- StoreSummary fields
- full address
- business hours
- phone
- website
- provider attribution
- navigation target

## 7. Out of scope for first vertical slice

- User-generated reviews
- Social graph
- AI-generated recommendations
- Reservations/orders
- Loyalty/payment
- Cross-provider review scraping
- Background location tracking
- Hermes/Codex automatic issue dispatch pipeline

## 8. Decisions still required

Before implementation of the first production vertical slice:
- Mobile framework: Flutter vs React Native.
- Backend runtime: .NET vs Go.
- First place-data provider and its license/cost constraints.
- Map/rendering provider.
- Authentication requirement for MVP.
- Persistence choice after confirming whether MVP needs accounts/favorites.

These decisions should be recorded in `docs/architecture.md` or ADRs before the affected implementation.
