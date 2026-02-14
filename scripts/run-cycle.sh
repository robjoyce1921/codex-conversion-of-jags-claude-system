#!/usr/bin/env bash
set -euo pipefail

# DECISION: Use one state-machine entrypoint because Codex lacks Claude-style runtime hook events.

project_root="$(pwd)"
proof_file="${PROOF_STATUS_FILE:-.codex/proof-status}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-cycle.sh [next [feature-name]]
  ./scripts/run-cycle.sh start <feature-name>
  ./scripts/run-cycle.sh pending
  ./scripts/run-cycle.sh verified
  ./scripts/run-cycle.sh ready
  ./scripts/run-cycle.sh status

Commands:
  next      Execute the next workflow step based on repo state (default)
  start     Validate plan and create a feature worktree (codex/<name>)
  pending   Set proof status to pending (tester handoff)
  verified  Set proof status to verified (after user confirmation)
  ready     Run full quality gates (make check)
  status    Print workflow status and recommended next command
EOF
}

sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

branch_name() {
  git rev-parse --abbrev-ref HEAD
}

read_proof_status() {
  if [[ ! -f "${proof_file}" ]]; then
    echo "missing|"
    return 0
  fi
  local status ts
  status="$(cut -d'|' -f1 "${proof_file}" || true)"
  ts="$(cut -d'|' -f2 "${proof_file}" || true)"
  echo "${status:-unknown}|${ts}"
}

show_status() {
  local branch proof status ts
  branch="$(branch_name)"
  proof="$(read_proof_status)"
  status="${proof%%|*}"
  ts="${proof#*|}"

  echo "Workflow status"
  echo "  branch: ${branch}"
  echo "  proof:  ${status}${ts:+ (${ts})}"
  if ./scripts/check-master-plan.sh >/dev/null 2>&1; then
    echo "  plan:   valid"
  else
    echo "  plan:   invalid"
  fi

  if [[ "${branch}" =~ ^(main|master)$ ]]; then
    echo "Next: ./scripts/run-cycle.sh start <feature-name>"
    return 0
  fi

  if [[ "${status}" == "missing" ]]; then
    echo "Next: ./scripts/run-cycle.sh pending"
    return 0
  fi

  if [[ "${status}" == "pending" ]]; then
    echo "Next: user verifies behavior, then run ./scripts/run-cycle.sh verified"
    return 0
  fi

  if [[ "${status}" == "verified" ]]; then
    echo "Next: ./scripts/run-cycle.sh ready"
    return 0
  fi

  echo "Next: ./scripts/run-cycle.sh pending"
}

start_work() {
  local feature="${1:-}"
  if [[ -z "${feature}" ]]; then
    echo "ERROR: feature name is required."
    usage
    exit 1
  fi

  ./scripts/check-master-plan.sh
  ./scripts/create-worktree.sh "${feature}"

  local safe_name
  safe_name="$(sanitize_name "${feature}")"
  echo "Next: cd ${project_root}/.worktrees/${safe_name}"
  echo "Then run implementer work and tester flow."
}

run_next() {
  local branch proof status feature
  feature="${1:-}"

  ./scripts/check-master-plan.sh

  branch="$(branch_name)"
  proof="$(read_proof_status)"
  status="${proof%%|*}"

  if [[ "${branch}" =~ ^(main|master)$ ]]; then
    if [[ -z "${feature}" ]]; then
      echo "ERROR: on ${branch}. Provide a feature name:"
      echo "  ./scripts/run-cycle.sh next <feature-name>"
      exit 1
    fi
    start_work "${feature}"
    return 0
  fi

  if [[ "${status}" == "missing" ]]; then
    ./scripts/set-proof-status.sh pending
    echo "Proof set to pending. Run tester verification with the user."
    return 0
  fi

  if [[ "${status}" == "pending" ]]; then
    echo "Waiting for user verification."
    echo "After confirmation, run: ./scripts/run-cycle.sh verified"
    return 0
  fi

  if [[ "${status}" == "verified" ]]; then
    make check
    echo "Quality gates passed. Ready for Guardian review and commit."
    return 0
  fi

  echo "Unknown proof status '${status}'. Reset with ./scripts/run-cycle.sh pending"
  exit 1
}

cmd="${1:-next}"
case "${cmd}" in
  next)
    shift || true
    run_next "${1:-}"
    ;;
  start)
    shift || true
    start_work "${1:-}"
    ;;
  pending)
    ./scripts/set-proof-status.sh pending
    ;;
  verified)
    ./scripts/set-proof-status.sh verified
    ;;
  ready)
    make check
    ;;
  status)
    show_status
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "ERROR: unknown command '${cmd}'"
    usage
    exit 1
    ;;
esac

