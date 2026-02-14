#!/usr/bin/env bash
set -euo pipefail

# DECISION: Use one state-machine entrypoint because Codex lacks Claude-style runtime hook events.

source "$(dirname "$0")/state-path.sh"

project_root="$(pwd)"
proof_file="${PROOF_STATUS_FILE:-$(resolve_state_file_for_read "proof-status")}"
stage_file="${STAGE_STATUS_FILE:-$(resolve_state_file_for_read "stage-status")}"
test_file="${TEST_STATUS_FILE:-$(resolve_state_file_for_read "test-status")}"
proposal_file="${PROPOSAL_STATUS_FILE:-$(resolve_state_file_for_read "proposal-status")}"
research_mode_file="${RESEARCH_MODE_FILE:-$(resolve_state_file_for_read "research-mode")}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-cycle.sh [next [feature-name] [codex-only|multi-provider]]
  ./scripts/run-cycle.sh start <feature-name> [codex-only|multi-provider]
  ./scripts/run-cycle.sh proposal-init
  ./scripts/run-cycle.sh proposal-pending
  ./scripts/run-cycle.sh proposal-approve
  ./scripts/run-cycle.sh proposal-revise
  ./scripts/run-cycle.sh research-mode <codex-only|multi-provider>
  ./scripts/run-cycle.sh research-run "<question>" [output-file]
  ./scripts/run-cycle.sh pending
  ./scripts/run-cycle.sh verified
  ./scripts/run-cycle.sh ready
  ./scripts/run-cycle.sh status
  ./scripts/run-cycle.sh summary

Commands:
  next      Execute the next workflow step based on repo state (default)
  start     Validate plan and create a feature worktree (codex/<name>)
  proposal-init     Create PROPOSAL.md scaffold and mark proposal draft
  proposal-pending  Validate proposal and mark ready for user review
  proposal-approve  Mark proposal approved and unlock implementing stage
  proposal-revise   Mark proposal needs-revision and return to proposal drafting
  research-mode     Set research mode for this feature cycle
  research-run      Execute research using selected mode (codex-only or multi-provider)
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

present_proposal_packet() {
  local proposal_doc="${1:-PROPOSAL.md}"
  if [[ ! -f "${proposal_doc}" ]]; then
    echo "ERROR: ${proposal_doc} not found"
    return 1
  fi
  echo "================ PROPOSAL REVIEW PACKET ================"
  echo "Review this proposal for approval or revision before implementation."
  echo "--------------------------------------------------------"
  cat "${proposal_doc}"
  echo "--------------------------------------------------------"
  echo "Decision required:"
  echo "  - Approve: ./scripts/run-cycle.sh proposal-approve"
  echo "  - Request revision: ./scripts/run-cycle.sh proposal-revise"
  echo "========================================================"
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

read_proposal_status() {
  read_state "${proposal_file}"
}

read_research_mode() {
  read_state "${research_mode_file}"
}

ensure_research_mode() {
  local requested_mode="${1:-}"
  if [[ -n "${requested_mode}" ]]; then
    ./scripts/set-research-mode.sh "${requested_mode}"
  fi
  ./scripts/check-research-mode.sh
}

show_status() {
  local branch proof stage test proposal research proof_status stage_status test_status proposal_status research_status proof_ts stage_ts test_ts proposal_ts research_ts
  branch="$(branch_name)"
  proof="$(read_proof_status)"
  stage="$(read_stage_status)"
  test="$(read_test_status)"
  proposal="$(read_proposal_status)"
  research="$(read_research_mode)"
  proof_status="${proof%%|*}"
  stage_status="${stage%%|*}"
  test_status="${test%%|*}"
  proposal_status="${proposal%%|*}"
  research_status="${research%%|*}"
  proof_ts="${proof#*|}"
  stage_ts="${stage#*|}"
  test_ts="${test#*|}"
  proposal_ts="${proposal#*|}"
  research_ts="${research#*|}"

  echo "Workflow status"
  echo "  branch: ${branch}"
  echo "  stage:  ${stage_status}${stage_ts:+ (${stage_ts})}"
  echo "  proposal: ${proposal_status}${proposal_ts:+ (${proposal_ts})}"
  echo "  research: ${research_status}${research_ts:+ (${research_ts})}"
  echo "  proof:  ${proof_status}${proof_ts:+ (${proof_ts})}"
  echo "  test:   ${test_status}${test_ts:+ (${test_ts})}"
  if ./scripts/check-master-plan.sh >/dev/null 2>&1; then
    echo "  plan:   valid"
  else
    echo "  plan:   invalid"
  fi
  ./scripts/check-plan-traceability.sh >/dev/null 2>&1 || true

  if [[ "${research_status}" == "missing" ]]; then
    echo "Next: choose research mode:"
    echo "  ./scripts/run-cycle.sh research-mode codex-only"
    echo "  ./scripts/run-cycle.sh research-mode multi-provider"
    return 0
  fi

  if [[ "${stage_status}" == "proposal-draft" || "${proposal_status}" == "draft" || "${proposal_status}" == "needs-revision" ]]; then
    echo "Next: build PROPOSAL.md then run ./scripts/run-cycle.sh proposal-pending"
    return 0
  fi

  if [[ "${stage_status}" == "proposal-pending" || "${proposal_status}" == "pending" ]]; then
    echo "Next: present proposal to user for review/feedback/approval"
    echo "If approved: ./scripts/run-cycle.sh proposal-approve"
    echo "If revisions needed: ./scripts/run-cycle.sh proposal-revise"
    return 0
  fi

  if [[ "${stage_status}" == "proposal-approved" || "${proposal_status}" == "approved" ]]; then
    echo "Next: ./scripts/run-cycle.sh next (implementation stage)"
    return 0
  fi

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
  local requested_mode="${2:-}"
  if [[ -z "${feature}" ]]; then
    echo "ERROR: feature name is required."
    usage
    exit 1
  fi

  ./scripts/check-master-plan.sh
  ./scripts/check-plan-traceability.sh || true
  ensure_research_mode "${requested_mode}"
  ./scripts/create-worktree.sh "${feature}"
  ./scripts/init-proposal.sh PROPOSAL.md
  ./scripts/set-proposal-status.sh draft
  ./scripts/set-stage-status.sh proposal-draft

  local safe_name
  safe_name="$(sanitize_name "${feature}")"
  echo "Next: cd ${project_root}/.worktrees/${safe_name}"
  echo "Research mode: $(./scripts/check-research-mode.sh --print)"
  echo "Optional research run: ./scripts/run-cycle.sh research-run \"<question>\""
  echo "Then develop proposal in PROPOSAL.md and run ./scripts/run-cycle.sh proposal-pending"
}

run_next() {
  local branch proof stage proposal proof_status stage_status proposal_status feature requested_mode research_mode
  feature="${1:-}"
  requested_mode="${2:-}"

  ./scripts/check-master-plan.sh
  ./scripts/check-plan-traceability.sh || true
  ./scripts/update-session-changes.sh >/dev/null 2>&1 || true

  branch="$(branch_name)"
  proof="$(read_proof_status)"
  stage="$(read_stage_status)"
  proposal="$(read_proposal_status)"
  proof_status="${proof%%|*}"
  stage_status="${stage%%|*}"
  proposal_status="${proposal%%|*}"

  if [[ "${stage_status}" == "missing" || "${stage_status}" == "planned" ]]; then
    if [[ "${branch}" =~ ^(main|master)$ ]] && [[ -z "${feature}" ]]; then
      echo "ERROR: on ${branch}. Provide a feature name:"
      echo "  ./scripts/run-cycle.sh next <feature-name>"
      exit 1
    fi
    if [[ "${branch}" =~ ^(main|master)$ ]]; then
      start_work "${feature}" "${requested_mode}"
      return 0
    fi
    ensure_research_mode "${requested_mode}"
    ./scripts/init-proposal.sh PROPOSAL.md
    ./scripts/set-proposal-status.sh draft
    ./scripts/set-stage-status.sh proposal-draft
    echo "Stage initialized to proposal-draft."
    echo "Next: write a robust proposal in PROPOSAL.md, then run ./scripts/run-cycle.sh proposal-pending"
    return 0
  fi

  if [[ "${stage_status}" == "proposal-draft" || "${proposal_status}" == "draft" || "${proposal_status}" == "needs-revision" ]]; then
    research_mode="$(./scripts/check-research-mode.sh --print)"
    if [[ "${research_mode}" == "multi-provider" ]]; then
      ./scripts/research-secrets.sh validate multi-provider
    fi
    ./scripts/check-proposal-quality.sh PROPOSAL.md
    ./scripts/set-proposal-status.sh pending
    ./scripts/set-stage-status.sh proposal-pending
    echo "Proposal is now pending user review."
    present_proposal_packet PROPOSAL.md
    return 0
  fi

  if [[ "${stage_status}" == "proposal-pending" || "${proposal_status}" == "pending" ]]; then
    echo "Waiting for user proposal decision."
    echo "If approved: ./scripts/run-cycle.sh proposal-approve"
    echo "If revisions needed: ./scripts/run-cycle.sh proposal-revise"
    return 0
  fi

  if [[ "${stage_status}" == "proposal-approved" || "${proposal_status}" == "approved" ]]; then
    if [[ "${branch}" =~ ^(main|master)$ ]]; then
      echo "Proposal approved."
      echo "Switch to your feature worktree and run ./scripts/run-cycle.sh next to enter implementing stage."
      return 0
    fi
    ./scripts/set-stage-status.sh implementing
    echo "Proposal approved. Implementation stage unlocked."
    echo "Continue implementation and run ./scripts/run-cycle.sh pending when demo-ready."
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
    run_next "${1:-}" "${2:-}"
    ;;
  start)
    shift || true
    start_work "${1:-}" "${2:-}"
    ;;
  proposal-init)
    ./scripts/check-research-mode.sh
    ./scripts/init-proposal.sh PROPOSAL.md
    ./scripts/set-proposal-status.sh draft
    ./scripts/set-stage-status.sh proposal-draft
    ;;
  proposal-pending)
    research_mode="$(./scripts/check-research-mode.sh --print)"
    if [[ "${research_mode}" == "multi-provider" ]]; then
      ./scripts/research-secrets.sh validate multi-provider
    fi
    ./scripts/check-proposal-quality.sh PROPOSAL.md
    ./scripts/set-proposal-status.sh pending
    ./scripts/set-stage-status.sh proposal-pending
    present_proposal_packet PROPOSAL.md
    ;;
  proposal-approve)
    ./scripts/check-proposal-quality.sh PROPOSAL.md
    ./scripts/set-proposal-status.sh approved
    ./scripts/set-stage-status.sh proposal-approved
    echo "Proposal approved. Run ./scripts/run-cycle.sh next to enter implementing stage."
    ;;
  proposal-revise)
    ./scripts/set-proposal-status.sh needs-revision
    ./scripts/set-stage-status.sh proposal-draft
    echo "Proposal marked needs-revision. Update PROPOSAL.md then run ./scripts/run-cycle.sh proposal-pending."
    ;;
  research-mode)
    shift || true
    ./scripts/set-research-mode.sh "${1:-}"
    ;;
  research-run)
    shift || true
    ./scripts/run-research.sh "${1:-}" "${2:-}"
    ;;
  pending)
    proposal_status="$(read_proposal_status)"
    if [[ "${proposal_status%%|*}" != "approved" ]]; then
      echo "ERROR: cannot enter testing checkpoint before proposal approval."
      echo "Run: ./scripts/run-cycle.sh proposal-approve (after user approval)"
      exit 1
    fi
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
