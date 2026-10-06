# Contributing

Read:
- `docs/SDD.md`
- `docs/architecture.md`
- `docs/engineering.md`
- the relevant GitHub Issue/OpenSpec change

All project development should use the DevContainer except the documented macOS/Xcode operations required by iOS.

Before opening a PR:
1. run `./scripts/repository-check.sh` inside the DevContainer
2. run formatting/linting and relevant tests for the changed module
3. verify no secrets are included
4. update affected specifications/docs
5. reference the GitHub Issue
