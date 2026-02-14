#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

status="${1:-}"
if [[ "${status}" != "pending" && "${status}" != "verified" ]]; then
  echo "Usage: $0 pending|verified"
  exit 1
fi

dir="$(state_dir_writable)"
echo "${status}|$(date +%s)" > "${dir}/proof-status"
echo "proof-status|${status}|$(date +%s)" > "${dir}/agent-findings"

echo "Set ${dir}/proof-status to ${status}"
