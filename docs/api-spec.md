# API Specification

Base path: `/api/v1`

This is an initial product contract, not yet bound to a specific backend framework.

## GET /stores/discover

Query parameters:
- `q`: optional free-text intent
- `category`: optional normalized category
- `lat`, `lng`: coordinates when location-based
- `radiusMeters`: bounded search radius
- `area`: manual area alternative
- `cursor`: optional pagination cursor

At least a discovery intent and usable location/area must be supplied.

### Response

```json
{
  "items": [
    {
      "storeId": "string",
      "name": "string",
      "categories": ["string"],
      "distanceMeters": 350,
      "openState": "open",
      "addressSummary": "string",
      "location": { "lat": 0, "lng": 0 },
      "source": "provider"
    }
  ],
  "nextCursor": null
}
```

## GET /stores/{storeId}

Returns normalized store detail including address, hours, contact fields, website, provider attribution and navigation coordinates when available.

## Error contract

```json
{
  "error": {
    "code": "DISCOVERY_PROVIDER_UNAVAILABLE",
    "message": "A safe user-facing message",
    "correlationId": "string"
  }
}
```

Provider-specific errors must not leak directly to mobile clients.
