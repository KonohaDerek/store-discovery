# Store Discovery

Store Discovery is a mobile-first application for discovering nearby stores and deciding where to go based on intent, location, availability, and useful store context.

## Current phase

**Phase 0 — Product foundation / MVP definition**

The repository is intentionally starting specification-first. App functionality should be implemented from an accepted SDD/OpenSpec change and tracked through GitHub Issues.

## Product goals

- Help users quickly discover relevant nearby stores.
- Support intent-based discovery instead of requiring an exact store name.
- Make results useful for real decisions: distance, open/closed state, category, and store details.
- Keep external place-data providers replaceable behind backend abstractions.
- Build iOS and Android from a shared product specification.

## Repository structure

```text
store-discovery/
├── .devcontainer/
├── docs/
│   ├── SDD.md
│   ├── architecture.md
│   ├── database.md
│   ├── api-spec.md
│   └── roadmap.md
├── mobile/
├── backend/
├── tests/
├── openspec/
├── docker-compose.yml
└── README.md
```

## Development rules

1. Development runs inside DevContainer.
2. Do not install project SDKs on the Mac host.
3. Product changes begin with SDD/OpenSpec.
4. Implementation must have tests appropriate to the change.
5. Work is tracked with GitHub Issues and delivered through branches and PRs.
6. Secrets and provider credentials must never be committed.

## Agent development flow

Hermes runs on the NAS and dispatches GitHub Issues over Tailscale SSH to the MacBook Worker. The worker uses the repository DevContainer for SDKs and dependencies, invokes Codex, runs checks, pushes a feature branch, and opens a PR. See [docs/agent-workflow.md](docs/agent-workflow.md).

## Initial MVP

The first vertical slice is:

**location → discovery query/category → store results → store detail**

Favorites, history, personalization, reviews aggregation, AI recommendations, social features, and advanced ranking are later phases unless promoted by an accepted spec.

See [docs/SDD.md](docs/SDD.md) and [docs/roadmap.md](docs/roadmap.md).
