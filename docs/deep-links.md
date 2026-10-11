# Store links

## Canonical format

Store Discovery uses one stable custom-scheme URI for sharing and app routing:

```text
store-discovery://store/<opaque-store-id>
```

`storeId` is the normalized backend identifier. It is encoded as one URI path
segment and is not a provider-specific URL.

## Runtime behavior

- The detail screen exposes a platform share action through `share_plus`.
- `app_links` reads the initial link and subsequent link events.
- A valid link opens the store detail screen and lets the API report a missing
  or stale store normally.
- Invalid schemes, hosts, paths, query parameters, and fragments are rejected
  with a user-facing message.
- The app does not persist incoming links or precise location data.

## Native runner setup

The repository currently contains Flutter source but no generated iOS or
Android runner. When the separate runner setup is created, register the custom
scheme with the `app_links` platform instructions:

- Android: add an intent filter for scheme `store-discovery` and host `store`.
- iOS: add `store-discovery` under `CFBundleURLTypes`.

Universal HTTPS links are intentionally deferred until a stable public domain
and its Apple association / Android asset files exist. Device-level iOS and
Android link tests therefore remain a runner setup acceptance item.
