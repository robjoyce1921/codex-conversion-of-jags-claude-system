# Codex Multi-Agent Workflow (Claude-System Conversion)

This repository implements a Codex-native equivalent of JAGS's Claude Code system:

- `Planner -> Implementer -> Tester -> Guardian` execution flow
- `MASTER_PLAN.md` required before implementation
- Hook-enforced safety and quality gates
- Command safety wrapper for risky git usage
- Worktree-first branch isolation with `codex/` branch prefix

## Attribution

This codebase was adapted from the work of developer **J. A. Guerrero-Saade (JAGS)**.

- X profile: `https://x.com/juanandres_gs`
- Original repository: `https://github.com/juanandresgs/claude-system`

`CODEX.md` in this repository is copied verbatim from the original and locked by checksum (`.codex-md.sha256`).

## Architecture Alignment

See `ARCHITECTURE.md` for the full Codex-mapped architecture model, including:

- system overview and flow
- state-file protocol in `.codex/`
- design decisions and extension points
- anti-patterns and glossary

State files are written to `.codex/` by default, with automatic fallback to `.codex-state/` if needed.

## Quick Start

1. Initialize git (if needed): `git init`
2. Install hooks and permissions: `./scripts/install-hooks.sh`
3. Start every task by updating `MASTER_PLAN.md`
4. Choose research mode at task start:
   - codex-only: `./scripts/run-cycle.sh research-mode codex-only`
   - multi-provider: `./scripts/run-cycle.sh research-mode multi-provider`
5. (Multi-provider only) configure provider tokens:
   - initialize local secrets file: `./scripts/research-secrets.sh init`
   - set keys: `./scripts/research-secrets.sh set OPENAI_API_KEY`, `./scripts/research-secrets.sh set PPLX_API_KEY`, `./scripts/research-secrets.sh set GEMINI_API_KEY`
   - validate: `./scripts/research-secrets.sh validate multi-provider`
6. Use the single orchestrator command:
   - from `main`: `./scripts/run-cycle.sh next my-feature`
   - inside feature branch/worktree: `./scripts/run-cycle.sh next`
7. Proposal gate (mandatory before implementation):
   - initialize proposal: `./scripts/run-cycle.sh proposal-init`
   - optionally run research: `./scripts/run-cycle.sh research-run "<research question>"`
   - mark proposal ready for review: `./scripts/run-cycle.sh proposal-pending`
   - after user approval: `./scripts/run-cycle.sh proposal-approve`
   - if revisions requested: `./scripts/run-cycle.sh proposal-revise`
8. Run work:
   - Planner guidance: `cat agents/planner.md`
   - Implementer guidance: `cat agents/implementer.md`
   - Tester guidance: `cat agents/tester.md`
   - Guardian guidance: `cat agents/guardian.md`
9. Verification cycle:
   - mark pending proof: `./scripts/run-cycle.sh pending`
   - after user verifies behavior: `./scripts/run-cycle.sh verified`
10. Run checks: `./scripts/run-cycle.sh ready`
11. Print session summary: `./scripts/run-cycle.sh summary`

## Orchestrator Command

`./scripts/run-cycle.sh` is the single workflow entrypoint.

- `next [feature-name]`: compute and execute the next step from current state
- `status`: print state + recommended next command
- `start <feature-name>`: validate plan and create worktree
- `proposal-init`: scaffold `PROPOSAL.md` and enter proposal-draft stage
- `proposal-pending`: validate proposal and present review packet for user decision
- `proposal-approve`: record user approval and unlock implementation
- `proposal-revise`: return to proposal drafting after user feedback
- `research-mode <codex-only|multi-provider>`: record research mode for this feature cycle
- `research-run "<question>" [output-file]`: execute codex-only brief generation or multi-provider synthesis
- `pending`: set tester proof status to pending
- `verified`: set proof status to verified
- `ready`: run full quality gates (`make check`)
- `summary`: print deterministic workflow/session summary from state files

## Guardrails Enforced by Hooks

- Block commits on `main`/`master` (unless explicitly overridden)
- Require `MASTER_PLAN.md` and required headings
- Require `CODEX.md` to match locked original wording
- Require `PROPOSAL.md` quality and explicit proposal approval before staged code commits
- Require explicit research mode selection and proposal alignment with that mode
- Snapshot plan traceability and plan drift into `.codex/plan-drift`
- Require `MASTER_PLAN.md` to be staged alongside code changes
- Block commits touching more than 10 files (configurable with `MAX_FILES`)
- Require decision annotations for larger code edits
- Require proof status `verified` before committing staged code changes
- Require stage `guardian-ready` before committing staged code changes
- Block non-fast-forward pushes (force-like pushes)
- Block pushes to protected branches by default

## Files

- `AGENTS.md`: Codex orchestration contract
- `ARCHITECTURE.md`: system architecture, extension points, glossary
- `MASTER_PLAN.md`: mandatory planning artifact
- `PROPOSAL.md`: research-backed proposal artifact requiring user approval before implementation
- `docs/PROPOSAL-TEMPLATE.md`: required structure for robust proposal development
- `scripts/research-secrets.sh`: local token lifecycle (`init`, `set`, `unset`, `status`, `validate`)
- `scripts/run-research.sh`: codex-only or OpenAI/Perplexity/Gemini research synthesis report generation
- `agents/`: role specs for Planner, Implementer, Tester, Guardian
- `.githooks/`: executable git hooks
- `scripts/`: reusable guard and validation scripts
- `docs/CODEX-CONVERSION-EXPLANATION.md`: mapping, explanation, limitations, and usage guide

## Overrides (Use Sparingly)

- `ALLOW_MAIN_COMMIT=1` (pre-commit)
- `ALLOW_MAIN_PUSH=1` (pre-push)
- `ALLOW_NON_FF_PUSH=1` (pre-push)
- `SKIP_TESTS=1` (checks)
- `MAX_FILES=10` (pre-commit file cap)
- `ALLOW_UNVERIFIED_COMMIT=1` (pre-commit proof gate override)
- `ALLOW_STAGE_BYPASS=1` (pre-commit stage gate override)
- `ALLOW_UNAPPROVED_PROPOSAL_COMMIT=1` (pre-commit proposal gate override)
- `STRICT_TRACEABILITY=1` (fail commit/check on plan traceability drift)
