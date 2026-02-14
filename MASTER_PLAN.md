# MASTER_PLAN

## Problem

Complete the interrupted Claude-to-Codex conversion by fully reading `juanandresgs/claude-system` docs and ensuring this local Codex workflow matches the upstream intent (architecture, hooks, multi-agent behavior, and operational guardrails).

## Constraints

- Technical constraints: Network reads rely on authenticated `gh` calls and may require escalated execution in this environment.
- Safety constraints: No destructive git commands; keep local changes isolated to this workspace.
- Scope constraints: Keep updates targeted to parity gaps discovered from upstream docs.

## Plan

1. Fetch and review all relevant upstream docs (`README.md`, `CODEX.md`, `docs/`, `hooks/`, `agents/`).
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
- 2026-02-14 00:55 - Bootstrapped standalone git repo in this folder, created initial commits, and published to GitHub.
- 2026-02-14 01:05 - Updated README attribution to explicitly credit J. A. Guerrero-Saade (JAGS) and the original claude-system repository.
- 2026-02-14 01:15 - Imported upstream JAGS `CODEX.md` verbatim and added checksum-based guard to prevent wording drift.
- 2026-02-14 01:30 - Added `ARCHITECTURE.md` for Codex alignment carrying original system concepts, anti-patterns, and glossary direction.
- 2026-02-14 01:35 - Added `.codex` state protocol scripts (`test-status`, `session-changes`, `agent-findings`, `plan-drift`, `stage-status`) and wired them to checks/hooks.
- 2026-02-14 01:40 - Upgraded `run-cycle.sh` to explicit stage-machine gating (implementing -> testing-pending -> testing-verified -> guardian-ready) with deterministic summary output.
- 2026-02-14 01:45 - Added state-path fallback (`.codex` primary, `.codex-state` fallback) to keep deterministic state writes in restricted environments.
- 2026-02-14 02:05 - Renamed `CLAUDE.md` to `CODEX.md`, renamed checksum lock to `.codex-md.sha256`, and updated script/documentation references.
- 2026-02-14 02:07 - Moved `EXPLANATION.md` into `docs/EXPLANATION.md` and updated guide references.
- 2026-02-14 02:20 - Collapsed `docs/EXPLANATION.md` and `docs/codex-conversion.md` into `docs/CODEX-CONVERSION-EXPLANATION.md`.

## Decisions

- DECISION: Use `gh api` for canonical repository reads because prior direct fetches were incomplete for `docs/`.
- DECISION: Add commit-time proof gate tied to `.codex/proof-status` to emulate upstream proof-before-commit enforcement.
- DECISION: Add a dedicated tester role to preserve separation between implementation and verification.
- DECISION: Implement orchestration as a state-machine command (`run-cycle.sh`) that computes the next step from branch/proof/plan state.
- DECISION: Treat `CODEX.md` as immutable guidance text by enforcing SHA-256 verification in pre-commit and `make check`.
- DECISION: Add architecture-level parity by codifying state-file lifecycle and glossary concepts in `ARCHITECTURE.md` plus executable gates.
- DECISION: Capture plan traceability drift in `.codex/plan-drift` with optional strict enforcement (`STRICT_TRACEABILITY=1`).
- DECISION: Use `.codex-state` as automatic fallback when `.codex` is not writable, preserving deterministic gate behavior.
- DECISION: Preserve verbatim guidance content while renaming artifact filenames to Codex-native naming (`CODEX.md`, `.codex-md.sha256`).

## Handoff

- Verification performed: Shell syntax checks for all hook/script files; `make check` passed.
- Residual risks: Codex still lacks native runtime PreToolUse/PostToolUse JSON hook events, so some lifecycle behaviors remain boundary-gated rather than per-tool-call gated.
- Follow-up actions: Optional future enhancement is an automated Task-dispatch layer that writes/reads `.codex/stage-status` and `.codex/agent-findings` across dedicated agent sessions.
