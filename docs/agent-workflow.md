# Agent Development Workflow

## Purpose

This document defines the smallest end-to-end path for using GitHub, Hermes, a MacBook coding worker, DevContainer, and Codex. It is an execution contract for `MVP-00 Foundation`; it does not add product functionality.

## Responsibilities

| Component | Responsibility |
|---|---|
| GitHub | Issue, branch, PR, review, and durable work history |
| Hermes on NAS Docker | Claim an Issue, create a job, dispatch it, monitor it, and report the result |
| MacBook Pro Worker | Receive the job over Tailscale SSH, create an isolated workspace, run the container, and return status |
| DevContainer | Provide project SDKs, dependencies, and test commands |
| Codex CLI | Read the Issue and repository specifications, edit code, and propose the smallest change |

OpenAB is not part of this POC.

## Target flow

```text
GitHub Issue
    ↓
Hermes claims the Issue and creates a job
    ↓  Tailscale / SSH
MacBook Pro Worker
    ↓
DevContainer
    ↓
Codex reads the Issue + SDD/OpenSpec and edits the repo
    ↓
Tests run inside the DevContainer
    ↓
feat/<issue>-<slug> branch
    ↓
Push branch and open PR
    ↓
Hermes reports PR URL and test result
```

## Job contract

Hermes sends a payload equivalent to:

```json
{
  "repository": "KonohaDerek/store-discovery",
  "issue_number": 55,
  "branch": "feat/55-agent-poc",
  "prompt": "Read docs/SDD.md and docs/agent-workflow.md. Make one small reviewable change, run the repository check, and open a PR."
}
```

The worker rejects a job if `repository`, `issue_number`, `branch`, or `prompt` is missing. Credentials are supplied by the worker environment; they are never placed in the payload, repository, Issue, commit, or PR body.

## Worker contract

1. Verify the repository and Issue are accessible and the Issue is open.
2. Create an isolated checkout for the requested branch. Never reuse a dirty workspace.
3. Start the repository DevContainer with `devcontainer up --workspace-folder <repo>`.
4. Run Codex against the checked-out repository with the Issue and this document as context.
5. Run the repository check inside the DevContainer.
6. Commit using Conventional Commit style and include `Refs #<issue>`.
7. Push the feature branch and open a PR that links the Issue.
8. Return `job_id`, branch, PR URL, test status, and a short failure reason when applicable.

The first POC may use a documentation-only change. It must still exercise the complete path.

## Safety boundaries

- One active job per workspace.
- No force-push or direct merge to `main`.
- The worker may modify only the checked-out repository.
- App SDKs and project dependencies run in the DevContainer, not on the Mac host.
- The iOS/Xcode toolchain is the documented macOS exception for simulator, signing, and distribution work.
- Secrets and provider credentials stay in environment/secret injection and never enter logs.
- A timeout or failed test leaves the branch available for inspection and reports `failed`; it does not retry blindly.

## POC acceptance criteria

The POC passes when a test Issue results in:

- Hermes dispatch over Tailscale SSH to the MacBook.
- A clean, isolated workspace on the MacBook.
- A successful DevContainer start without host SDK installation.
- One small Codex-authored change.
- A passing repository check executed in the DevContainer.
- A pushed `feat/<issue>-<slug>` branch.
- A PR linked to the Issue with the check result.
- A final Hermes report containing the PR URL and status.

## GitHub setup

Use these repository objects for the POC:

- Milestone: `MVP-00 Foundation`
- Labels: `area:agent`, `area:devcontainer`, `area:github`, `MVP-00`
- Issue: `[MVP-00] Run GitHub → Hermes → MacBook → DevContainer → Codex → PR POC`

After the first run is stable, the worker can be generalized for app implementation Issues. Product milestones remain governed by [roadmap.md](roadmap.md).

