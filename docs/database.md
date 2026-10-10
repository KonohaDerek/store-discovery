# Database Design

## MVP position

The initial discovery flow should not require a database merely to proxy place search. Persistence is introduced only for a concrete use case such as favorites, user preferences, provider normalization cache, audit requirements, or accounts.

## Candidate persisted entities

### User
Only if authentication enters MVP.

### FavoriteStore
- userId
- canonicalStoreId
- createdAt

### StoreReference
A lightweight canonical reference when user-owned data needs to survive provider changes.
- canonicalStoreId
- provider
- providerStoreId
- lastKnownName
- lastKnownCoordinates
- updatedAt

## Current mobile favorite model

The mobile MVP keeps favorites in session-local memory, keyed by the normalized
API `storeId`. It stores the loaded `StoreSummary` only while the app session is
active, supports local favorite / unfavorite without a network call, and does
not persist provider payloads. Durable local storage and account sync remain
out of scope until the account decision in #44.

## Rules

- Do not mirror an external provider's entire place database.
- Respect provider storage/caching/license restrictions.
- Do not persist raw user location by default.
- Schema choice remains pending until persistence requirements are accepted.
