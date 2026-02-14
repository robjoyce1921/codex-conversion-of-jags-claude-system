# Codex Multi-Agent Workflow (Claude-System Conversion)

This repository implements a Codex-native equivalent of JAGS's Claude Code system:

- `Planner -> Implementer -> Tester -> Guardian` execution flow
- `MASTER_PLAN.md` required before implementation
- Hook-enforced safety and quality gates
- Command safety wrapper for risky git usage
- Worktree-first branch isolation with `codex/` branch prefix

## Quick Start

1. Initialize git (if needed): `git init`
2. Install hooks and permissions: `./scripts/install-hooks.sh`
3. Start every task by updating `MASTER_PLAN.md`
4. Use the single orchestrator command:
   - from `main`: `./scripts/run-cycle.sh next my-feature`
   - inside feature branch/worktree: `./scripts/run-cycle.sh next`
5. Run work:
   - Planner guidance: `cat agents/planner.md`
   - Implementer guidance: `cat agents/implementer.md`
   - Tester guidance: `cat agents/tester.md`
   - Guardian guidance: `cat agents/guardian.md`
6. Verification cycle:
   - mark pending proof: `./scripts/run-cycle.sh pending`
   - after user verifies behavior: `./scripts/run-cycle.sh verified`
7. Run checks: `./scripts/run-cycle.sh ready`

## Orchestrator Command

`./scripts/run-cycle.sh` is the single workflow entrypoint.

- `next [feature-name]`: compute and execute the next step from current state
- `status`: print state + recommended next command
- `start <feature-name>`: validate plan and create worktree
- `pending`: set tester proof status to pending
- `verified`: set proof status to verified
- `ready`: run full quality gates (`make check`)

## Guardrails Enforced by Hooks

- Block commits on `main`/`master` (unless explicitly overridden)
- Require `MASTER_PLAN.md` and required headings
- Require `MASTER_PLAN.md` to be staged alongside code changes
- Block commits touching more than 10 files (configurable with `MAX_FILES`)
- Require decision annotations for larger code edits
- Require proof status `verified` before committing staged code changes
- Block non-fast-forward pushes (force-like pushes)
- Block pushes to protected branches by default

## Files

- `AGENTS.md`: Codex orchestration contract
- `MASTER_PLAN.md`: mandatory planning artifact
- `agents/`: role specs for Planner, Implementer, Tester, Guardian
- `.githooks/`: executable git hooks
- `scripts/`: reusable guard and validation scripts
- `docs/codex-conversion.md`: mapping from Claude-system to Codex-system

## Overrides (Use Sparingly)

- `ALLOW_MAIN_COMMIT=1` (pre-commit)
- `ALLOW_MAIN_PUSH=1` (pre-push)
- `ALLOW_NON_FF_PUSH=1` (pre-push)
- `SKIP_TESTS=1` (checks)
- `MAX_FILES=10` (pre-commit file cap)
- `ALLOW_UNVERIFIED_COMMIT=1` (pre-commit proof gate override)
