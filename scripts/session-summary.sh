#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

read_state() {
  local rel="${1}"
  local file
  file="$(resolve_state_file_for_read "${rel}")"
  if [[ ! -f "${file}" ]]; then
    echo "missing|"
    return 0
  fi
  cat "${file}"
}

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"
dirty_count="$(git status --porcelain | wc -l | tr -d ' ')"
test_status="$(read_state "test-status")"
proof_status="$(read_state "proof-status")"
stage_status="$(read_state "stage-status")"
proposal_status="$(read_state "proposal-status")"
research_mode="$(read_state "research-mode")"
plan_drift="$(read_state "plan-drift")"

changes_count=0
session_changes_file="$(resolve_state_file_for_read "session-changes")"
if [[ -f "${session_changes_file}" ]]; then
  changes_count="$(rg -n '^[^\[]' "${session_changes_file}" | sed '/timestamp|/d' | wc -l | tr -d ' ')"
fi

echo "Session summary"
echo "  branch: ${branch}"
echo "  dirty-files: ${dirty_count}"
echo "  tracked-session-lines: ${changes_count}"
echo "  test-status: ${test_status}"
echo "  proof-status: ${proof_status}"
echo "  stage-status: ${stage_status}"
echo "  proposal-status: ${proposal_status}"
echo "  research-mode: ${research_mode}"
echo "  plan-drift:"
echo "${plan_drift}" | sed 's/^/    /'

stage="${stage_status%%|*}"
proof="${proof_status%%|*}"
proposal="${proposal_status%%|*}"
research="${research_mode%%|*}"
if [[ "${research}" == "missing" ]]; then
  echo "Next: set research mode first:"
  echo "  ./scripts/run-cycle.sh research-mode codex-only"
  echo "  ./scripts/run-cycle.sh research-mode multi-provider"
elif [[ "${stage}" == "proposal-draft" || "${proposal}" == "draft" || "${proposal}" == "needs-revision" ]]; then
  echo "Next: complete PROPOSAL.md and run ./scripts/run-cycle.sh proposal-pending"
elif [[ "${stage}" == "proposal-pending" || "${proposal}" == "pending" ]]; then
  echo "Next: present proposal to user and capture approval/revision decision"
elif [[ "${stage}" == "proposal-approved" || "${proposal}" == "approved" ]]; then
  if [[ "${branch}" =~ ^(main|master)$ ]]; then
    echo "Next: switch to feature worktree, then run ./scripts/run-cycle.sh next"
  else
    echo "Next: ./scripts/run-cycle.sh next to enter implementation"
  fi
elif [[ "${branch}" =~ ^(main|master)$ ]]; then
  echo "Next: ./scripts/run-cycle.sh start <feature-name>"
elif [[ "${stage}" == "implementing" ]]; then
  echo "Next: when implementation is demo-ready run ./scripts/run-cycle.sh pending"
elif [[ "${stage}" == "testing-pending" || "${proof}" == "pending" ]]; then
  echo "Next: obtain user verification, then ./scripts/run-cycle.sh verified"
elif [[ "${stage}" == "testing-verified" || "${proof}" == "verified" ]]; then
  echo "Next: ./scripts/run-cycle.sh ready"
elif [[ "${stage}" == "guardian-ready" ]]; then
  echo "Next: Guardian commit/push flow"
else
  echo "Next: ./scripts/run-cycle.sh status"
fi
