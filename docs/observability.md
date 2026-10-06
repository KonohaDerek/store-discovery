# Observability

OpenTelemetry is the baseline for the backend.

## Logs
Structured logs with:
- timestamp
- severity
- service/version/environment
- correlation/request ID
- route/operation
- normalized error code

Do not log provider credentials or precise user coordinates.

## Metrics
Initial metrics:
- HTTP request count/latency/error rate
- discovery request count
- empty-result rate
- provider request count/latency/error rate
- provider timeout/rate-limit count

## Traces
Trace:
mobile request correlation → API → application use case → provider adapter.

Provider spans should include operation/provider/status, but not sensitive query/location payloads.

## Health
- `/health/live`
- `/health/ready`

Readiness should reflect required local service readiness; external provider transient failure should not necessarily restart the application.
