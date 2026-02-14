.PHONY: install-hooks check check-plan check-codex check-proposal check-research-mode check-traceability check-files check-decisions check-proof check-stage check-tests session-summary proposal-init proposal-pending proposal-approved proposal-revise proof-pending proof-verified research-mode research-run research-secrets-init research-secrets-status research-secrets-validate research-secrets-set research-secrets-unset worktree cycle cycle-status cycle-ready cycle-summary

install-hooks:
	./scripts/install-hooks.sh

check: check-plan check-codex check-proposal check-research-mode check-traceability check-files check-decisions check-proof check-stage check-tests

check-plan:
	./scripts/check-master-plan.sh

check-codex:
	./scripts/check-codex-guidance-verbatim.sh

check-proposal:
	PROPOSAL_OPTIONAL=1 ./scripts/check-proposal-quality.sh PROPOSAL.md

check-research-mode:
	./scripts/check-research-mode.sh

check-traceability:
	./scripts/check-plan-traceability.sh

check-files:
	./scripts/check-changed-file-count.sh

check-decisions:
	./scripts/check-decision-annotations.sh

check-proof:
	./scripts/check-proof-status.sh

check-stage:
	./scripts/check-stage-gate.sh

check-tests:
	./scripts/check-tests.sh

session-summary:
	./scripts/session-summary.sh

proposal-init:
	./scripts/run-cycle.sh proposal-init

proposal-pending:
	./scripts/run-cycle.sh proposal-pending

proposal-approved:
	./scripts/run-cycle.sh proposal-approve

proposal-revise:
	./scripts/run-cycle.sh proposal-revise

research-mode:
	@if [ -z "$(MODE)" ]; then echo "Usage: make research-mode MODE=codex-only|multi-provider"; exit 1; fi
	./scripts/run-cycle.sh research-mode "$(MODE)"

research-run:
	@if [ -z "$(QUESTION)" ]; then echo "Usage: make research-run QUESTION='<research question>' [OUT='research/output.md']"; exit 1; fi
	./scripts/run-cycle.sh research-run "$(QUESTION)" "$(OUT)"

research-secrets-init:
	./scripts/research-secrets.sh init

research-secrets-status:
	./scripts/research-secrets.sh status

research-secrets-validate:
	./scripts/research-secrets.sh validate

research-secrets-set:
	@if [ -z "$(KEY)" ]; then echo "Usage: make research-secrets-set KEY=OPENAI_API_KEY [VALUE=...]"; exit 1; fi
	./scripts/research-secrets.sh set "$(KEY)" "$(VALUE)"

research-secrets-unset:
	@if [ -z "$(KEY)" ]; then echo "Usage: make research-secrets-unset KEY=OPENAI_API_KEY"; exit 1; fi
	./scripts/research-secrets.sh unset "$(KEY)"

proof-pending:
	./scripts/set-proof-status.sh pending
	./scripts/set-stage-status.sh testing-pending

proof-verified:
	./scripts/set-proof-status.sh verified
	./scripts/set-stage-status.sh testing-verified

worktree:
	@if [ -z "$(NAME)" ]; then echo "Usage: make worktree NAME=<feature-name>"; exit 1; fi
	./scripts/create-worktree.sh "$(NAME)"

cycle:
	@if [ -z "$(NAME)" ]; then ./scripts/run-cycle.sh next; else ./scripts/run-cycle.sh next "$(NAME)"; fi

cycle-status:
	./scripts/run-cycle.sh status

cycle-ready:
	./scripts/run-cycle.sh ready

cycle-summary:
	./scripts/run-cycle.sh summary
