#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

if [[ "${ALLOW_UNVERIFIED_COMMIT:-0}" == "1" ]]; then
  echo "ALLOW_UNVERIFIED_COMMIT=1 set; skipping proof gate"
  exit 0
fi

pattern='\.(c|cc|cpp|h|hpp|go|java|js|jsx|py|rb|rs|sh|swift|ts|tsx|zsh)$'
staged_code="$(git diff --cached --name-only --diff-filter=ACMR | rg "${pattern}" || true)"

if [[ -z "${staged_code}" ]]; then
  echo "OK: no staged code files for proof gate"
  exit 0
fi

proof_file="${PROOF_STATUS_FILE:-$(resolve_state_file_for_read "proof-status")}"
if [[ ! -f "${proof_file}" ]]; then
  dir="$(state_dir_writable)"
  echo "proof-gate|missing proof status file|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proof status missing at ${proof_file}"
  echo "Run tester flow and set status: ./scripts/set-proof-status.sh pending|verified"
  exit 1
fi

status="$(cut -d'|' -f1 "${proof_file}" || true)"
timestamp="$(cut -d'|' -f2 "${proof_file}" || true)"

if [[ "${status}" != "verified" ]]; then
  dir="$(state_dir_writable)"
  echo "proof-gate|proof status must be verified (current=${status:-unknown})|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proof status is '${status:-unknown}', expected 'verified'"
  echo "Run tester flow and mark verification complete."
  exit 1
fi

echo "OK: proof status verified (${timestamp:-no-timestamp})"
