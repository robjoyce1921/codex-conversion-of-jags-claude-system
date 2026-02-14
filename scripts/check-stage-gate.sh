#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

if [[ "${ALLOW_STAGE_BYPASS:-0}" == "1" ]]; then
  echo "ALLOW_STAGE_BYPASS=1 set; skipping stage gate"
  exit 0
fi

pattern='\.(c|cc|cpp|h|hpp|go|java|js|jsx|py|rb|rs|sh|swift|ts|tsx|zsh)$'
staged_code="$(git diff --cached --name-only --diff-filter=ACMR | rg "${pattern}" || true)"

if [[ -z "${staged_code}" ]]; then
  echo "OK: no staged code files for stage gate"
  exit 0
fi

status_file="${STAGE_STATUS_FILE:-$(resolve_state_file_for_read "stage-status")}"
if [[ ! -f "${status_file}" ]]; then
  dir="$(state_dir_writable)"
  echo "stage-gate|missing stage status for code commit|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: stage status missing at ${status_file}"
  echo "Set stage with: ./scripts/set-stage-status.sh guardian-ready"
  exit 1
fi

status="$(cut -d'|' -f1 "${status_file}" || true)"
if [[ "${status}" != "guardian-ready" ]]; then
  dir="$(state_dir_writable)"
  echo "stage-gate|stage must be guardian-ready before code commit (current=${status:-unknown})|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: stage is '${status:-unknown}', expected 'guardian-ready'"
  echo "Complete tester verification and run: ./scripts/run-cycle.sh ready"
  exit 1
fi

echo "OK: stage gate passed (${status})"
