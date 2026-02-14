# MASTER_PLAN

## Original Intent

Implement a Codex-equivalent research workflow that starts with an explicit user choice:

1. `codex-only` research
2. `multi-provider` cross-provider synthesis (OpenAI + Perplexity + Gemini)

Also implement secrets-management capabilities needed to securely configure and validate access tokens for those three providers.

## Problem

The current Codex conversion includes a proposal gate and research sections, but it does not enforce a start-of-task research mode selection or provide first-class multi-provider orchestration with secure token lifecycle management.

## Constraints

- Technical constraints: Shell-first implementation; provider APIs must be optional and fail clearly when tokens are absent.
- Safety constraints: No destructive git commands; no secret material committed to git.
- Scope constraints: Keep implementation focused on research mode orchestration, provider synthesis tooling, and secrets lifecycle.

## Requirements

- REQ-RES-001: User must choose research mode at cycle start (`codex-only` or `multi-provider`).
- REQ-RES-002: Workflow state must persist research mode in `.codex/` (or fallback) and surface it in status/summary.
- REQ-RES-003: Proposal quality gate must require explicit documentation of selected research mode.
- REQ-RES-004: Multi-provider mode must support running OpenAI, Perplexity, and Gemini research queries and generate a synthesis artifact.
- REQ-RES-005: Secrets management must provide secure local storage, set/unset/status operations, and provider-specific validation checks.
- REQ-RES-006: Hooks/checks/docs must guide users through configuration and block invalid multi-provider execution early.

## Success Metrics

- MET-RES-001: `run-cycle` can set and report research mode deterministically.
- MET-RES-002: Multi-provider run command can generate a synthesis report when keys are configured.
- MET-RES-003: Missing/invalid secrets produce actionable errors before provider calls.
- MET-RES-004: `make check` passes with new research and secrets gates.

## Plan

1. Planner: update docs/contracts (`MASTER_PLAN.md`, template/check expectations) to include research mode.
2. Implementer: add research state scripts and `run-cycle` integration for mode selection at start.
3. Implementer: add secrets manager (`init`, `set`, `unset`, `status`, `validate`) with non-committed local storage.
4. Implementer: add multi-provider research runner and synthesis artifact generation.
5. Implementer: wire Makefile/check scripts/docs (`README.md`, `AGENTS.md`, `ARCHITECTURE.md`, planner guidance, conversion explanation).
6. Guardian: run syntax and gate checks; record residual risks and next steps.

## Acceptance Criteria

- [x] Research mode is explicitly chosen and persisted before proposal progression.
- [x] Proposal template/checks require a research-mode section.
- [x] Secrets manager supports OpenAI/Perplexity/Gemini token lifecycle operations.
- [x] Multi-provider research run generates a synthesis report artifact.
- [x] `.gitignore` protects local secret files.
- [x] `make check` passes after changes.

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
- 2026-02-14 02:35 - Added mandatory research-backed proposal phase with `PROPOSAL.md`, proposal quality checks, and explicit user approval gate before implementation.
- 2026-02-14 02:40 - Extended run-cycle stage model with proposal stages and automated proposal review packet output for user review/feedback/approval.
- 2026-02-14 09:58 - Planned research-mode expansion with multi-provider synthesis and secrets-management capabilities.
- 2026-02-14 10:00 - Implemented research mode state scripts, run-cycle integration (`research-mode`, `research-run`), and session/status reporting.
- 2026-02-14 10:01 - Added secrets lifecycle manager for OpenAI/PPLX/Gemini keys (`init`, `set`, `unset`, `status`, `validate`) with local ignored storage.
- 2026-02-14 10:01 - Added provider runner to produce codex-only research briefs or multi-provider synthesis reports with raw artifact capture.
- 2026-02-14 10:02 - Updated proposal quality/template/docs to require explicit research mode and provider coverage in multi-provider proposals.
- 2026-02-14 10:03 - Verified via `bash -n` and `make check`; smoke-tested codex-only research run and multi-provider missing-secret failure path.

## Architectural Decisions

- DEC-RES-001: Enforce explicit research mode selection as a first-class workflow state at start. Addresses: REQ-RES-001, REQ-RES-002.
- DEC-RES-002: Keep codex-only and multi-provider in one orchestrator by gating provider execution on persisted mode + key validation. Addresses: REQ-RES-001, REQ-RES-004, REQ-RES-006.
- DEC-RES-003: Use local ignored env files with strict file permissions for token storage and script-based lifecycle management. Addresses: REQ-RES-005.
- DEC-RES-004: Require proposal documentation of selected research mode to preserve traceability and review quality. Addresses: REQ-RES-003.

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
- DECISION: Block staged code commits unless proposal is both high-quality and explicitly approved (`proposal-status=approved`).
- DECISION: Require robust proposal sections (problem decomposition, research findings, options/trade-offs, recommended architecture, phase plan, risks, evaluation plan) before entering implementation.
- DECISION: Add research mode state and mandatory selection at workflow start so research execution path is deterministic.
- DECISION: Implement multi-provider synthesis through provider adapters plus consolidated markdown artifact for proposal ingestion.
- DECISION: Manage provider tokens through ignored local secrets files and explicit validation gates instead of committed config.

## Handoff

- Verification performed: `bash -n scripts/*.sh .githooks/pre-commit .githooks/pre-push`; `make check`; `run-cycle` status/summary smoke; `run-research.sh` codex-only output generation; multi-provider key validation failure-path test.
- Residual risks: Live multi-provider API success path is unverified in this environment because provider keys were intentionally not configured.
- Follow-up actions: Optional enhancements include provider timeout/retry tuning, citation schema normalization, and a strict gate that requires a fresh research artifact before proposal approval.
