# Backend

Store Discovery backend workspace.

Responsibilities:
- discovery API
- provider abstraction/adapters
- normalized domain contracts
- ranking/orchestration
- observability

The backend is an ASP.NET Core .NET 10 modular-monolith host. The first scaffold
exposes liveness/readiness health endpoints and keeps provider integration out of
the default test path.

## Checks

```bash
dotnet restore backend/StoreDiscovery.sln
dotnet build backend/StoreDiscovery.sln --configuration Release
dotnet test backend/StoreDiscovery.sln --configuration Release
```

Endpoints:

- `GET /health/live`
- `GET /health/ready`
- `GET /api/v1/health`
- `GET /api/v1/stores/discover`
- `GET /api/v1/stores/{storeId}`

The discovery endpoint currently uses a deterministic `SampleStoreProvider` so
the mobile vertical slice can be exercised without paid or live provider calls.
The Google Places adapter remains behind `IStoreProvider` and is the next
provider integration step.

Discovery ranking is provider-independent: open stores rank before unknown and
closed stores, then results sort by ascending distance, case-insensitive name,
and stable store ID. `radiusMeters` requires coordinates and uses great-circle
distance in meters; area-only queries retain fixture distance values until a
provider supplies a location-relative distance.
