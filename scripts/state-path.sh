#!/usr/bin/env bash
set -euo pipefail

primary_state_dir="${CODEX_STATE_DIR:-.codex}"
fallback_state_dir="${CODEX_STATE_FALLBACK_DIR:-.codex-state}"

state_dir() {
  echo "${primary_state_dir}"
}

state_dir_writable() {
  local dir
  dir="$(state_dir)"
  mkdir -p "${dir}" 2>/dev/null || true
  local probe="${dir}/.write-probe.$$"
  if ( : > "${probe}" ) 2>/dev/null; then
    rm -f "${probe}" || true
    echo "${dir}"
    return 0
  fi

  mkdir -p "${fallback_state_dir}"
  echo "${fallback_state_dir}"
}

resolve_state_file_for_read() {
  local rel="${1}"
  local primary="${primary_state_dir}/${rel}"
  local fallback="${fallback_state_dir}/${rel}"
  if [[ -f "${primary}" ]]; then
    echo "${primary}"
    return 0
  fi
  if [[ -f "${fallback}" ]]; then
    echo "${fallback}"
    return 0
  fi
  echo "${primary}"
}

