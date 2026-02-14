# Architecture: Codex Conversion of JAGS Claude-System

**@decision DEC-ARCH-001**  
**@title Architecture reference for Codex enforcement model**  
**@status accepted**  
**@rationale** Keep the original system intent intact while mapping enforcement to Codex capabilities.

---

## 1. System Overview

This repository is a Codex-native implementation of JAGS's process architecture:

- Deterministic policy checks (git hooks + scripts)
- Specialized agents (Planner, Implementer, Tester, Guardian)
- Worktree-first implementation flow (`codex/*` branches)
- State-file coordination in `.codex/`

### Component Diagram

```
User request
   |
   v
CODEX.md (verbatim, locked)
   |
   v
Codex orchestration contract (AGENTS.md)
   |
   +--> Planner      -> MASTER_PLAN.md / decisions
   +--> Implementer  -> code + tests + decision annotations
   +--> Tester       -> proof collection + verification request
   +--> Guardian     -> final checks + commit/push operations
                    |
                    v
         git hooks + check scripts (mechanical gates)
                    |
                    v
                main branch
```

### Enforcement Surfaces

- Pre-commit (`.githooks/pre-commit`)
- Pre-push (`.githooks/pre-push`)
- Orchestrator state machine (`scripts/run-cycle.sh`)
- Check suite (`make check`)

---

## 2. Data Flow: End-to-End

1. Planner updates `MASTER_PLAN.md`.
2. Guardian/bootstrap creates feature workspace context (`scripts/create-worktree.sh`) and proposal draft stage.
3. Planner creates a robust `PROPOSAL.md` and marks proposal `pending`.
4. User reviews proposal and either requests revision or approves.
5. Proposal approval unlocks implementation stage.
6. Implementer develops and runs tests.
7. Tester marks proof `pending` and then `verified` after user confirmation.
8. Orchestrator marks stage `guardian-ready`.
9. Guardian commits/pushes through hook gates.

---

## 3. Execution Model

Codex does not expose Claude-style runtime PreToolUse/PostToolUse JSON hooks.  
This system uses deterministic script/hook gates at operation boundaries:

- On commit: plan validity, immutable guidance, file-count, decision annotation, traceability, proof state, tests, stage gate.
- On push: protected-branch policy and non-fast-forward safety.
- During orchestration: explicit stage-state transitions and session summaries.

---

## 4. State Files

All state files are stored under `.codex/`:

- `.codex/test-status` (`pass|fail|pending|count|epoch`)
- `.codex/proof-status` (`verified|pending|epoch`)
- `.codex/proposal-status` (`draft|pending|approved|needs-revision|epoch`)
- `.codex/research-mode` (`codex-only|multi-provider|epoch`)
- `.codex/stage-status` (`planned|proposal-draft|proposal-pending|proposal-approved|implementing|testing-pending|testing-verified|guardian-ready|epoch`)
- `.codex/session-changes` (current git working/staged file lists)
- `.codex/agent-findings` (latest gate findings and blockers)
- `.codex/plan-drift` (traceability/drift snapshot)

If `.codex/` is not writable in the current execution environment, scripts automatically fall back to `.codex-state/`.

---

## 5. Key Design Decisions

### DEC-ARCH-002: Verbatim guidance lock
`CODEX.md` is copied verbatim from upstream and guarded by SHA-256 (`.codex-md.sha256`).

### DEC-ARCH-003: Stage-gated orchestration
`run-cycle.sh` plus proposal/stage gates enforce Planner -> Proposal Review -> Implementer -> Tester -> Guardian sequencing.

### DEC-ARCH-004: State-file first coordination
Cross-step coordination uses `.codex/*` state files so checks remain deterministic and auditable.

### DEC-ARCH-005: Traceability drift capture
`check-plan-traceability.sh` writes `.codex/plan-drift` to capture REQ/DEC linkage quality and drift signals.

### DEC-ARCH-006: Explicit research-mode fork
The workflow records research mode at task start and uses it to choose either Codex-only research or multi-provider synthesis.

### DEC-ARCH-007: Local secrets lifecycle for provider tokens
Provider tokens are managed via local ignored env files with script-driven set/unset/status/validate controls.

---

## 6. Extension Points

### Add a Gate

1. Create a script in `scripts/`.
2. Return non-zero to block.
3. Add to `Makefile` and/or `.githooks/pre-commit`.
4. Record findings in `.codex/agent-findings`.

### Add an Agent

1. Add `agents/<role>.md`.
2. Wire stage transitions in `scripts/run-cycle.sh`.
3. Add any required state checks to pre-commit/pre-push gates.

### Add a State File

1. Define writer and reader scripts.
2. Keep format explicit and parseable.
3. Document in this file and `README.md`.

---

## 7. Anti-Patterns

- Relying on instructions alone without mechanical checks
- Working directly on `main`
- Skipping proof collection before commit
- Skipping proposal review/approval before implementation
- Skipping plan updates when code changes
- Tracking workflow state only in memory
- Treating plan/code drift as acceptable without explicit rationale

---

## 8. Glossary

**Sacred Practices**  
Core rules enforced mechanically (plan-first, protected main, tests/proof before permanent operations).

**Worktree**  
Isolated git working directory for feature implementation.

**@decision / DECISION:**  
Inline rationale marker linking code choices to plan intent.

**Proof-of-work**  
Verification checkpoint requiring observable evidence before commit.

**Proposal Review Gate**  
Mandatory user decision point after first proposal development: approve to proceed or request revision.

**Research Mode**  
Explicit choice between `codex-only` and `multi-provider` that determines research execution behavior.

**Cross-Provider Synthesis**  
Structured aggregation and reconciliation of OpenAI, Perplexity, and Gemini outputs into a single proposal-ingestion artifact.

**Test status gate**  
Mechanism requiring current test status before permanent operations.

**Transparent rewrite**  
Automatic conversion of unsafe command forms to safer alternatives (implemented here via guarded wrapper and push policies).

**State file**  
File-based cross-step communication artifact under `.codex/`.

**Phase boundary**  
Point where plan state/status is advanced and decision rationale is reconciled.

**Plan drift**  
Gap between requirements/decisions in plan and current code implementation.
