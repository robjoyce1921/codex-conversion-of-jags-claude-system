# Claude-System -> Codex-System Mapping

Reviewed upstream artifacts for this parity pass:
- `README.md`, `CODEX.md`, `ARCHITECTURE.md`
- `docs/context-management-sota-2026.md`
- `docs/team-walkthrough-presentation.md`
- `hooks/HOOKS.md`
- `agents/planner.md`, `agents/implementer.md`, `agents/tester.md`, `agents/guardian.md`

## Direct Mapping

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

## Practical Usage Pattern

1. Update `MASTER_PLAN.md`
2. Create isolated worktree (`make worktree NAME=<feature>`)
3. Execute implementation in small batches
4. Run Tester and set proof status (`make proof-pending` then `make proof-verified`)
5. Run `make check`
6. Submit for Guardian review

## Known Platform Differences

1. Codex does not currently expose Claude-style runtime PreToolUse/PostToolUse event hooks.
2. This implementation enforces equivalent controls at commit/push boundaries plus explicit scripts for proof/worktree flow.
3. SessionStart/Stop-style runtime context injection is approximated via documented process, not automatic tool-event hooks.
