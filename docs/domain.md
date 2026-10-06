# Domain Model

## DiscoveryQuery
- query: optional free text
- category: optional normalized category
- latitude/longitude OR area
- radiusMeters
- locale
- cursor

A request must contain usable discovery intent and a usable location/area.

## Normalized categories — v1
- food.restaurant
- food.cafe
- food.bakery
- retail.convenience
- retail.supermarket
- retail.shopping
- health.pharmacy
- health.clinic
- service.beauty
- service.laundry
- service.automotive
- leisure.entertainment
- leisure.fitness
- lodging.hotel
- other

Provider categories are adapter input, never public API categories. Unknown provider types map to the closest accepted category only when deterministic; otherwise `other`.

## StoreSummary
- storeId: opaque Store Discovery identifier/reference
- name
- categories[]
- location
- addressSummary
- distanceMeters
- openState: open | closed | unknown
- source

## StoreDetail
StoreSummary plus:
- fullAddress
- businessHours
- phone
- website
- navigationTarget
- attribution

Unknown data stays unknown; it must never be synthesized as fact.

## Compatibility
Public mobile contracts are versioned under `/api/v1`. Additive optional fields are preferred. Breaking semantic/schema changes require a new API version or an explicit coordinated migration.
