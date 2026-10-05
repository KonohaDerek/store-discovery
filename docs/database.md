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

## Rules

- Do not mirror an external provider's entire place database.
- Respect provider storage/caching/license restrictions.
- Do not persist raw user location by default.
- Schema choice remains pending until persistence requirements are accepted.
