#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

test -s README.md
test -s docs/SDD.md
test -s docs/agent-workflow.md
jq empty .devcontainer/devcontainer.json
git diff --check

echo "repository check passed"
