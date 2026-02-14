#!/usr/bin/env bash
set -euo pipefail

# DECISION: Use one state-machine entrypoint because Codex lacks Claude-style runtime hook events.

source "$(dirname "$0")/state-path.sh"

project_root="$(pwd)"
proof_file="${PROOF_STATUS_FILE:-$(resolve_state_file_for_read "proof-status")}"
stage_file="${STAGE_STATUS_FILE:-$(resolve_state_file_for_read "stage-status")}"
test_file="${TEST_STATUS_FILE:-$(resolve_state_file_for_read "test-status")}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-cycle.sh [next [feature-name]]
  ./scripts/run-cycle.sh start <feature-name>
  ./scripts/run-cycle.sh pending
  ./scripts/run-cycle.sh verified
  ./scripts/run-cycle.sh ready
  ./scripts/run-cycle.sh status
  ./scripts/run-cycle.sh summary

Commands:
  next      Execute the next workflow step based on repo state (default)
  start     Validate plan and create a feature worktree (codex/<name>)
  pending   Set proof status to pending (tester handoff)
  verified  Set proof status to verified (after user confirmation)
  ready     Run full quality gates (make check)
  status    Print workflow status and recommended next command
  summary   Print session summary from .codex state files
EOF
}

sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

branch_name() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main
}

read_state() {
  local file="${1}"
  if [[ ! -f "${file}" ]]; then
    echo "missing|"
    return 0
  fi
  cat "${file}"
}

read_proof_status() {
  read_state "${proof_file}"
}

read_stage_status() {
  read_state "${stage_file}"
}

read_test_status() {
  read_state "${test_file}"
}

show_status() {
  local branch proof stage test proof_status stage_status test_status proof_ts stage_ts test_ts
  branch="$(branch_name)"
  proof="$(read_proof_status)"
  stage="$(read_stage_status)"
  test="$(read_test_status)"
  proof_status="${proof%%|*}"
  stage_status="${stage%%|*}"
  test_status="${test%%|*}"
  proof_ts="${proof#*|}"
  stage_ts="${stage#*|}"
  test_ts="${test#*|}"

  echo "Workflow status"
  echo "  branch: ${branch}"
  echo "  stage:  ${stage_status}${stage_ts:+ (${stage_ts})}"
  echo "  proof:  ${proof_status}${proof_ts:+ (${proof_ts})}"
  echo "  test:   ${test_status}${test_ts:+ (${test_ts})}"
  if ./scripts/check-master-plan.sh >/dev/null 2>&1; then
    echo "  plan:   valid"
  else
    echo "  plan:   invalid"
  fi
  ./scripts/check-plan-traceability.sh >/dev/null 2>&1 || true

  if [[ "${stage_status}" == "guardian-ready" ]]; then
    echo "Next: Guardian commit/push flow"
    return 0
  fi

  if [[ "${branch}" =~ ^(main|master)$ ]]; then
    echo "Next: ./scripts/run-cycle.sh start <feature-name>"
    return 0
  fi

  if [[ "${stage_status}" == "missing" || "${stage_status}" == "planned" || "${stage_status}" == "implementing" ]]; then
    echo "Next: when implementation is ready run ./scripts/run-cycle.sh pending"
    return 0
  fi

  if [[ "${stage_status}" == "testing-pending" || "${proof_status}" == "pending" ]]; then
    echo "Next: user verifies behavior, then run ./scripts/run-cycle.sh verified"
    return 0
  fi

  if [[ "${stage_status}" == "testing-verified" || "${proof_status}" == "verified" ]]; then
    echo "Next: ./scripts/run-cycle.sh ready"
    return 0
  fi

  echo "Next: ./scripts/run-cycle.sh status"
}

start_work() {
  local feature="${1:-}"
  if [[ -z "${feature}" ]]; then
    echo "ERROR: feature name is required."
    usage
    exit 1
  fi

  ./scripts/check-master-plan.sh
  ./scripts/check-plan-traceability.sh || true
  ./scripts/create-worktree.sh "${feature}"
  ./scripts/set-stage-status.sh implementing

  local safe_name
  safe_name="$(sanitize_name "${feature}")"
  echo "Next: cd ${project_root}/.worktrees/${safe_name}"
  echo "Then run implementer work and tester flow."
}

run_next() {
  local branch proof stage proof_status stage_status feature
  feature="${1:-}"

  ./scripts/check-master-plan.sh
  ./scripts/check-plan-traceability.sh || true
  ./scripts/update-session-changes.sh >/dev/null 2>&1 || true

  branch="$(branch_name)"
  proof="$(read_proof_status)"
  stage="$(read_stage_status)"
  proof_status="${proof%%|*}"
  stage_status="${stage%%|*}"

  if [[ "${branch}" =~ ^(main|master)$ ]]; then
    if [[ -z "${feature}" ]]; then
      echo "ERROR: on ${branch}. Provide a feature name:"
      echo "  ./scripts/run-cycle.sh next <feature-name>"
      exit 1
    fi
    start_work "${feature}"
    return 0
  fi

  if [[ "${stage_status}" == "missing" || "${stage_status}" == "planned" ]]; then
    ./scripts/set-stage-status.sh implementing
    echo "Stage initialized to implementing."
    echo "Next: complete implementer work, then run ./scripts/run-cycle.sh pending"
    return 0
  fi

  if [[ "${stage_status}" == "implementing" ]]; then
    echo "Implementer stage active."
    echo "Next: when ready for user verification run ./scripts/run-cycle.sh pending"
    return 0
  fi

  if [[ "${stage_status}" == "testing-pending" || "${proof_status}" == "pending" ]]; then
    echo "Waiting for user verification."
    echo "After confirmation, run: ./scripts/run-cycle.sh verified"
    return 0
  fi

  if [[ "${stage_status}" == "testing-verified" || "${proof_status}" == "verified" ]]; then
    make check
    ./scripts/set-stage-status.sh guardian-ready
    ./scripts/update-session-changes.sh >/dev/null 2>&1 || true
    echo "Quality gates passed. Ready for Guardian review and commit."
    return 0
  fi

  if [[ "${stage_status}" == "guardian-ready" ]]; then
    echo "Stage is guardian-ready. Proceed with Guardian commit/push flow."
    return 0
  fi

  echo "Unknown stage/proof state (stage=${stage_status}, proof=${proof_status})."
  echo "Reset with: ./scripts/set-stage-status.sh implementing && ./scripts/set-proof-status.sh pending"
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
    ./scripts/set-stage-status.sh testing-pending
    ./scripts/update-session-changes.sh >/dev/null 2>&1 || true
    ;;
  verified)
    ./scripts/set-proof-status.sh verified
    ./scripts/set-stage-status.sh testing-verified
    ./scripts/update-session-changes.sh >/dev/null 2>&1 || true
    ;;
  ready)
    make check
    ./scripts/set-stage-status.sh guardian-ready
    ./scripts/session-summary.sh
    ;;
  status)
    show_status
    ;;
  summary)
    ./scripts/session-summary.sh
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
