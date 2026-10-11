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
Set `StoreDiscovery__Provider=google` and provide `GooglePlaces__ApiKey` to use
the Google Places API (New) adapter. The API key is read only by the backend;
mobile clients never receive it. The default `sample` provider remains the
deterministic test path. Discovery uses an explicit field mask and a bounded
`GooglePlaces__MaxResultCount` (1–20); place details are fetched only when the
detail endpoint is requested. Google-backed detail responses include the
provider attribution required by the mobile presentation.

Discovery ranking is provider-independent: open stores rank before unknown and
closed stores, then results sort by ascending distance, case-insensitive name,
and stable store ID. `radiusMeters` requires coordinates and uses great-circle
distance in meters; area-only queries retain fixture distance values until a
provider supplies a location-relative distance.
