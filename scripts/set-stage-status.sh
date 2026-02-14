#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

status="${1:-}"
case "${status}" in
  planned|implementing|testing-pending|testing-verified|guardian-ready)
    ;;
  *)
    echo "Usage: $0 planned|implementing|testing-pending|testing-verified|guardian-ready"
    exit 1
    ;;
esac

dir="$(state_dir_writable)"
echo "${status}|$(date +%s)" > "${dir}/stage-status"
echo "Set ${dir}/stage-status to ${status}"
