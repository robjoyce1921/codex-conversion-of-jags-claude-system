# CODEX-CONVERSION-EXPLANATION

## Claude-System -> Codex-System Mapping

Reviewed upstream artifacts for this parity pass:
- `README.md`, `CODEX.md`, `ARCHITECTURE.md`
- `docs/context-management-sota-2026.md`
- `docs/team-walkthrough-presentation.md`
- `hooks/HOOKS.md`
- `agents/planner.md`, `agents/implementer.md`, `agents/tester.md`, `agents/guardian.md`

### Direct Mapping

1. Multi-agent architecture
   - Claude: Planner, Implementer, Tester, Guardian agent docs
   - Codex: `agents/planner.md`, `agents/implementer.md`, `agents/tester.md`, `agents/guardian.md`, orchestrated by `AGENTS.md`

2. Plan-first execution
   - Claude: `MASTER_PLAN.md` required before implementation
   - Codex: `MASTER_PLAN.md` enforced by `scripts/check-master-plan.sh` in pre-commit

3. Scope cap per pass
   - Claude: max file-change threshold before pause/handoff
   - Codex: `scripts/check-changed-file-count.sh` blocks commits over `MAX_FILES` (default 10)

4. Decision annotations
   - Claude: document non-obvious changes
   - Codex: `scripts/check-decision-annotations.sh` requires inline `DECISION:` notes for larger edits

5. Command safety
   - Claude hooks: prevent destructive patterns and force-push misuse
   - Codex: `scripts/git-safe.sh` blocks reset/checkout restore and rewrites push force flags

6. Push and branch protections
   - Claude hooks: safety checks in lifecycle hooks
   - Codex: `.githooks/pre-push` + `scripts/check-push-safety.sh` enforce branch and fast-forward policy

7. Proof-before-commit gate
   - Claude: proof-of-work status is required before permanent git operations
   - Codex: `scripts/check-proof-status.sh` + `.githooks/pre-commit` require `.codex/proof-status` = `verified` for staged code commits

8. Worktree-first isolation
   - Claude: Guardian sets isolated worktrees before implementation
   - Codex: `scripts/create-worktree.sh` creates `.worktrees/<feature>` on `codex/<feature>` branch

9. Single orchestration entrypoint
   - Claude: runtime orchestrator delegates phases with lifecycle hooks
   - Codex: `scripts/run-cycle.sh` provides a deterministic state-machine entrypoint (`next/start/pending/verified/ready/status`)

10. Architecture-level alignment
   - Claude: `ARCHITECTURE.md` defines flow, state files, anti-patterns, glossary
   - Codex: `ARCHITECTURE.md` now defines equivalent concepts and maps them to commit/push/check orchestration

11. State-file model
   - Claude: `.claude/.test-status`, `.proof-status`, `.session-changes`, `.agent-findings`, `.plan-drift`
   - Codex: `.codex/test-status`, `.codex/proof-status`, `.codex/session-changes`, `.codex/agent-findings`, `.codex/plan-drift`, `.codex/stage-status` (fallback `.codex-state/*` when `.codex` is not writable)

### Practical Usage Pattern

1. Update `MASTER_PLAN.md`
2. Create isolated worktree (`make worktree NAME=<feature>`)
3. Execute implementation in small batches
4. Run Tester and set proof status (`make proof-pending` then `make proof-verified`)
5. Run `make check`
6. Submit for Guardian review

### Known Platform Differences

1. Codex does not currently expose Claude-style runtime PreToolUse/PostToolUse event hooks.
2. This implementation enforces equivalent controls at commit/push boundaries plus explicit scripts for proof/worktree flow.
3. SessionStart/Stop-style runtime context injection is approximated via documented process, not automatic tool-event hooks.

## How This Approach Guides Codex and Enforces Deterministic Development Practices

This repository implements a process architecture that makes Codex follow a structured software delivery path instead of ad-hoc coding.

The workflow is built around role separation:

- Planner: defines problem framing and plan artifacts in `MASTER_PLAN.md`
- Implementer: builds incrementally in isolated worktrees
- Tester: validates behavior and requests user verification
- Guardian: performs final quality and git-integrity operations

Deterministic enforcement is provided by executable gates rather than prompt-only guidance:

- `scripts/run-cycle.sh` enforces explicit stage progression
  - `implementing -> testing-pending -> testing-verified -> guardian-ready`
- `.githooks/pre-commit` enforces policy before commit
  - plan presence and structure checks
  - immutable `CODEX.md` checksum lock
  - file-count guard
  - decision-annotation guard
  - proof gate
  - stage gate
  - test gate
- `.githooks/pre-push` enforces push safety
  - protected branch behavior
  - non-fast-forward protections

State files make orchestration inspectable and repeatable:

- proof state (`proof-status`)
- test state (`test-status`)
- stage state (`stage-status`)
- change and drift snapshots (`session-changes`, `plan-drift`)
- gate findings (`agent-findings`)

Together, these mechanisms create deterministic pathways for safe development, verification, and integration.

## Differences and Limitations vs the Original JAGS Claude Approach

The original JAGS Claude system uses Claude-specific runtime hook events (for example tool-lifecycle and session-lifecycle hooks) with JSON stdin/stdout interception semantics.

This Codex version differs in important ways:

1. No native Claude-style runtime tool-event hook model  
   Codex does not provide the same PreToolUse/PostToolUse/SessionStart/Stop interception primitives used by Claude.

2. Enforcement boundary is shifted  
   Determinism is enforced mainly at commit/push/check boundaries and via explicit orchestration commands, rather than on every individual tool invocation.

3. Command rewrite parity is partial  
   Some command-safety behavior is implemented through wrappers and push/commit gates, not universal transparent runtime rewriting for all tool calls.

4. Session-context injection parity is partial  
   The Claude model can inject hook context continuously at runtime; this Codex version emulates that with state files and explicit status/summary commands.

5. Subagent lifecycle automation parity is partial  
   The original uses richer subagent lifecycle hooks; here, stage gates and `run-cycle` state transitions provide the equivalent control plane.

The core architectural intent remains aligned: guidance + deterministic enforcement, role separation, worktree isolation, proof-before-permanent-operations, and plan/decision traceability.

## How to Develop Using This Approach with Codex

Use this workflow for every feature:

1. Read guidance artifacts
   - `CODEX.md` (verbatim locked)
   - `ARCHITECTURE.md`
   - `MASTER_PLAN.md`

2. Plan first
   - update `MASTER_PLAN.md` before implementation work
   - ensure requirements and decisions are explicit

3. Start a feature cycle
   - from main: `./scripts/run-cycle.sh next <feature-name>`
   - this creates a worktree and initializes stage flow

4. Implement in the worktree
   - write code and tests incrementally
   - use decision annotations for non-obvious implementation choices

5. Move to tester checkpoint
   - `./scripts/run-cycle.sh pending`
   - gather evidence and get user verification
   - `./scripts/run-cycle.sh verified`

6. Gate all quality checks
   - `./scripts/run-cycle.sh ready`
   - or `make check`

7. Use Guardian flow for permanent operations
   - commit and push only when stage is `guardian-ready`
   - hooks enforce policy and safety constraints

8. Inspect status and summary at any point
   - `./scripts/run-cycle.sh status`
   - `./scripts/run-cycle.sh summary`

This keeps development intentional, auditable, and mechanically constrained to high-quality software delivery practices.
