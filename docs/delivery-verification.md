# Delivery verification

The repository delivers two independently verifiable artifacts:

- an internal debug APK attached to a GitHub Release;
- a backend container published to GHCR and identified by an immutable digest.

The source PR check is `.github/workflows/delivery-check.yml`. It runs the
backend build/tests and the Flutter analyze/tests/debug APK build. It generates
the Android runner inside the CI workspace, so Android SDK files do not need to
be committed to the repository or installed on the Mac host.

## Publish a delivery

After the delivery workflow is merged, create and push a semantic version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

`.github/workflows/publish-delivery.yml` then:

1. builds and smoke-tests the sample-provider API container;
2. publishes `ghcr.io/konohaderek/store-discovery:sha-<commit>` and the release tag;
3. builds the Flutter debug APK;
4. creates a GitHub Release containing the APK, its SHA-256 file, and a delivery
   manifest containing the GHCR digest.

Set the repository variable `STORE_DISCOVERY_API_BASE_URL` before tagging when
the APK should target a deployed API. If it is empty, the APK still verifies
the mobile build and opens the app's unconfigured-service state; it is not an
end-to-end environment test.

## Verify the published artifacts

From the GitHub Release page, download the APK and checksum, then run:

```bash
sha256sum -c store-discovery-v0.1.0.apk.sha256
```

The release manifest provides an immutable image reference. Authenticate to
GHCR if the package is private, then run the API health check:

```bash
docker pull ghcr.io/konohaderek/store-discovery@sha256:<digest>
docker run --rm -p 8080:8080 \
  -e StoreDiscovery__Provider=sample \
  ghcr.io/konohaderek/store-discovery@sha256:<digest>
curl --fail http://127.0.0.1:8080/health/live
```

The APK is an internal debug artifact. Production signing, store submission,
Google Maps API-key provisioning, iOS signing/distribution, and automatic
dev/staging/production promotion remain separate release controls. This PR
establishes the repeatable build and artifact evidence needed before those
environment-specific controls are selected.
