#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  exec git
fi

first="${1}"
shift

if [[ "${first}" == "checkout" && "${1:-}" == "--" ]]; then
  echo "Blocked: 'git checkout --' is disabled by safety policy."
  exit 1
fi

if [[ "${first}" == "reset" ]]; then
  for arg in "$@"; do
    if [[ "${arg}" == "--hard" ]]; then
      echo "Blocked: 'git reset --hard' is disabled by safety policy."
      exit 1
    fi
  done
fi

if [[ "${first}" == "push" ]]; then
  args=()
  rewrote=0
  for arg in "$@"; do
    if [[ "${arg}" == "--force" ]]; then
      args+=("--force-with-lease")
      rewrote=1
    else
      args+=("${arg}")
    fi
  done
  if (( rewrote == 1 )); then
    echo "Rewriting --force to --force-with-lease"
  fi
  exec git push "${args[@]}"
fi

exec git "${first}" "$@"

