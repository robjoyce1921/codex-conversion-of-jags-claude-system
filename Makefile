.PHONY: install-hooks check check-plan check-files check-decisions check-proof check-tests proof-pending proof-verified worktree cycle cycle-status cycle-ready

install-hooks:
	./scripts/install-hooks.sh

check: check-plan check-files check-decisions check-proof check-tests

check-plan:
	./scripts/check-master-plan.sh

check-files:
	./scripts/check-changed-file-count.sh

check-decisions:
	./scripts/check-decision-annotations.sh

check-proof:
	./scripts/check-proof-status.sh

check-tests:
	./scripts/check-tests.sh

proof-pending:
	./scripts/set-proof-status.sh pending

proof-verified:
	./scripts/set-proof-status.sh verified

worktree:
	@if [ -z "$(NAME)" ]; then echo "Usage: make worktree NAME=<feature-name>"; exit 1; fi
	./scripts/create-worktree.sh "$(NAME)"

cycle:
	@if [ -z "$(NAME)" ]; then ./scripts/run-cycle.sh next; else ./scripts/run-cycle.sh next "$(NAME)"; fi

cycle-status:
	./scripts/run-cycle.sh status

cycle-ready:
	./scripts/run-cycle.sh ready
