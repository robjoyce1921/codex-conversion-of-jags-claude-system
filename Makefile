.PHONY: install-hooks check check-plan check-codex check-traceability check-files check-decisions check-proof check-stage check-tests session-summary proof-pending proof-verified worktree cycle cycle-status cycle-ready cycle-summary

install-hooks:
	./scripts/install-hooks.sh

check: check-plan check-codex check-traceability check-files check-decisions check-proof check-stage check-tests

check-plan:
	./scripts/check-master-plan.sh

check-codex:
	./scripts/check-codex-guidance-verbatim.sh

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
