# Codex Multi-Agent Contract

This repository uses a strict multi-agent workflow:

1. `Planner`: scopes, decomposes, and updates `MASTER_PLAN.md`
2. `Implementer`: executes exactly against `MASTER_PLAN.md`
3. `Tester`: verifies live behavior and collects proof before commit
4. `Guardian`: performs independent review, git operations, and final quality checks

## Operating Rules

1. Planning-first: do not implement until `MASTER_PLAN.md` is updated for the task.
2. Scope control: each implementation pass should touch at most 10 files.
3. Decision logging: non-obvious logic requires inline `DECISION:` annotation and an entry in `MASTER_PLAN.md`.
4. Safety-first git: never use destructive restore/reset patterns.
5. Verification before handoff: run checks and provide a concise risk report.

## Required Flow

1. Read `CODEX.md` verbatim.
2. Read `ARCHITECTURE.md`.
3. Read `MASTER_PLAN.md`
4. Select research mode at task start (`codex-only` or `multi-provider`)
5. Run Planner protocol from `agents/planner.md`
6. Complete proposal review gate (`PROPOSAL.md`: pending -> approved or needs-revision)
7. Run Implementer protocol from `agents/implementer.md`
8. Run Tester protocol from `agents/tester.md`
9. Run Guardian protocol from `agents/guardian.md`
10. Summarize findings, residual risks, and next steps

## Shared Concepts

Use concepts from `ARCHITECTURE.md` consistently:

- Sacred Practices
- Worktree isolation
- Proof-of-work before commit
- Proposal review and approval before implementation
- Phase boundaries and plan drift
- State-file communication in `.codex/`

## Codex Delegation Guidance

- If operating in one Codex session, emulate agents sequentially with explicit phase labels.
- If running separate sessions, give each role only task-relevant context plus `MASTER_PLAN.md`.
- Never skip Tester or Guardian review for code changes.
