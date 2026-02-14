# MASTER_PLAN

## Problem

Complete the interrupted Claude-to-Codex conversion by fully reading `juanandresgs/claude-system` docs and ensuring this local Codex workflow matches the upstream intent (architecture, hooks, multi-agent behavior, and operational guardrails).

## Constraints

- Technical constraints: Network reads rely on authenticated `gh` calls and may require escalated execution in this environment.
- Safety constraints: No destructive git commands; keep local changes isolated to this workspace.
- Scope constraints: Keep updates targeted to parity gaps discovered from upstream docs.

## Plan

1. Fetch and review all relevant upstream docs (`README.md`, `CLAUDE.md`, `docs/`, `hooks/`, `agents/`).
2. Compare upstream behavior to current local Codex scaffold and identify mismatches.
3. Implement parity fixes across docs/scripts/hooks with explicit rationale for non-obvious choices.
4. Run `make check` and summarize findings, residual risks, and next actions.

## Acceptance Criteria

- [ ] Upstream `docs/` content is reviewed and parity deltas are documented.
- [ ] Local workflow behavior reflects upstream intent for plan-first, multi-agent flow, and safety/quality gates.
- [ ] All local checks pass.
- [ ] Final handoff includes mapping, remaining gaps, and recommended follow-ups.

## Progress Log

- 2026-02-14 00:00 - Resumed interrupted conversion and defined parity completion plan.
- 2026-02-14 00:15 - Retrieved and reviewed upstream `docs/`, `hooks/HOOKS.md`, `settings.json`, and full agent specs.
- 2026-02-14 00:25 - Implemented parity upgrades: tester role, proof gate, and worktree bootstrap.
- 2026-02-14 00:27 - Ran local validation (`bash -n` on hooks/scripts and `make check`) with passing results.
- 2026-02-14 00:40 - Added `scripts/run-cycle.sh` single orchestrator entrypoint and integrated Makefile/README usage.
- 2026-02-14 00:42 - Re-validated with `run-cycle` smoke tests and full `make check`.

## Decisions

- DECISION: Use `gh api` for canonical repository reads because prior direct fetches were incomplete for `docs/`.
- DECISION: Add commit-time proof gate tied to `.codex/proof-status` to emulate upstream proof-before-commit enforcement.
- DECISION: Add a dedicated tester role to preserve separation between implementation and verification.
- DECISION: Implement orchestration as a state-machine command (`run-cycle.sh`) that computes the next step from branch/proof/plan state.

## Handoff

- Verification performed: Shell syntax checks for all hook/script files; `make check` passed.
- Residual risks: Codex lacks native Claude-style runtime tool-event hooks, so enforcement remains strongest at commit/push boundaries.
- Follow-up actions: Optional future enhancement is `run-cycle` integration with Task delegation so it can spawn dedicated Planner/Implementer/Tester/Guardian sessions automatically.
