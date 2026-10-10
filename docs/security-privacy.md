# Security & Privacy Baseline

## Location
- Ask for device location only when the user invokes location-dependent discovery.
- Denial must preserve manual-area discovery.
- Do not persist precise user location by default.
- Do not place raw precise coordinates in normal logs, traces, analytics or error messages.
- Any future location history requires a new explicit product/privacy decision.

## Recent searches
- Recent searches are session-only and retain only keyword, category and
  manually entered area.
- Device coordinates are never included in recent-search history.
- History is limited to five entries and can be cleared from the search screen.

## Secrets
- Never commit API keys, tokens, signing material or service credentials.
- Repository contains only variable names/examples.
- Local/CI/staging/production secrets are injected externally.
- Mobile applications must not contain privileged backend/provider secrets.

## Provider data
- Follow provider attribution, caching, storage and display terms.
- Google Places content must not be mirrored into an internal place database.
- Persist provider identifiers only where provider terms allow.

## API
- Validate all external input.
- Bound radius/page sizes.
- Apply provider timeouts and resilience controls.
- Normalize upstream errors.
- Add abuse/rate controls before public exposure.

## Future accounts
Before accounts are introduced, define deletion/export, retention, authentication lifecycle and migration of anonymous local data.
