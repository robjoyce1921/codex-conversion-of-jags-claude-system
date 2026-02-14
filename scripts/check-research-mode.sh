#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"
# DECISION: Require explicit research mode selection to avoid ambiguous research execution paths.

print_mode=0
if [[ "${1:-}" == "--print" ]]; then
  print_mode=1
fi

mode_file="${RESEARCH_MODE_FILE:-$(resolve_state_file_for_read "research-mode")}" 
if [[ ! -f "${mode_file}" ]]; then
  if [[ "${RESEARCH_MODE_OPTIONAL:-0}" == "1" ]]; then
    echo "WARN: research mode not set (optional mode)"
    exit 0
  fi
  dir="$(state_dir_writable)"
  echo "research-mode|missing|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: research mode is not set"
  echo "Choose one at task start:"
  echo "  ./scripts/run-cycle.sh research-mode codex-only"
  echo "  ./scripts/run-cycle.sh research-mode multi-provider"
  exit 1
fi

mode="$(cut -d'|' -f1 "${mode_file}" || true)"
case "${mode}" in
  codex-only|multi-provider)
    ;;
  *)
    dir="$(state_dir_writable)"
    echo "research-mode|invalid (${mode:-unknown})|$(date +%s)" > "${dir}/agent-findings"
    echo "ERROR: invalid research mode '${mode:-unknown}' in ${mode_file}"
    echo "Reset with ./scripts/set-research-mode.sh codex-only|multi-provider"
    exit 1
    ;;
esac

if [[ "${print_mode}" == "1" ]]; then
  echo "${mode}"
  exit 0
fi

echo "OK: research mode is ${mode}"
