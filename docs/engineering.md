# Engineering Standards

## Workflow
SDD/OpenSpec → Issue → branch → implementation → tests → review → PR.

Hermes automatic dispatch is deferred and is not part of the Definition of Done.

## Branches
- `feat/<issue>-<slug>`
- `fix/<issue>-<slug>`
- `chore/<issue>-<slug>`
- `docs/<issue>-<slug>`

## Commits
Use Conventional Commit style where practical: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`.

## Pull requests
A PR must:
- reference its Issue
- explain behavior/contract changes
- include appropriate tests
- pass CI
- avoid secrets
- update SDD/API/architecture docs when contracts or decisions change

## Definition of Done
- Acceptance criteria satisfied
- Formatting/lint checks pass
- Unit/contract/integration tests appropriate to change pass
- No live paid provider dependency in default tests
- Observability added for new external/service boundaries
- Security/privacy impact reviewed
- Documentation updated

## Toolchains
Project SDKs are pinned in DevContainer. macOS/Xcode is the explicit exception required for iOS simulator/build/signing/distribution.
