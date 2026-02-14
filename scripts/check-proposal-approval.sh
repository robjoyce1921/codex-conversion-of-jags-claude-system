#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"
# DECISION: Keep proposal approval as a hard gate for staged code unless explicit override is set.

if [[ "${ALLOW_UNAPPROVED_PROPOSAL_COMMIT:-0}" == "1" ]]; then
  echo "ALLOW_UNAPPROVED_PROPOSAL_COMMIT=1 set; skipping proposal approval gate"
  exit 0
fi

pattern='\.(c|cc|cpp|h|hpp|go|java|js|jsx|py|rb|rs|sh|swift|ts|tsx|zsh)$'
staged_code="$(git diff --cached --name-only --diff-filter=ACMR | rg "${pattern}" || true)"

if [[ -z "${staged_code}" ]]; then
  echo "OK: no staged code files for proposal gate"
  exit 0
fi

./scripts/check-proposal-quality.sh PROPOSAL.md
./scripts/check-research-mode.sh

status_file="${PROPOSAL_STATUS_FILE:-$(resolve_state_file_for_read "proposal-status")}"
if [[ ! -f "${status_file}" ]]; then
  dir="$(state_dir_writable)"
  echo "proposal-gate|missing proposal-status for code commit|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proposal status missing at ${status_file}"
  echo "Run: ./scripts/set-proposal-status.sh approved (only after user approval)"
  exit 1
fi

status="$(cut -d'|' -f1 "${status_file}" || true)"
if [[ "${status}" != "approved" ]]; then
  dir="$(state_dir_writable)"
  echo "proposal-gate|proposal not approved (current=${status:-unknown})|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proposal status is '${status:-unknown}', expected 'approved'"
  echo "Present proposal to user, collect feedback, and approve before code commit."
  exit 1
fi

echo "OK: proposal approval gate passed (${status})"
