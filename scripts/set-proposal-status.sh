#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

status="${1:-}"
case "${status}" in
  draft|pending|approved|needs-revision)
    ;;
  *)
    echo "Usage: $0 draft|pending|approved|needs-revision"
    exit 1
    ;;
esac

dir="$(state_dir_writable)"
echo "${status}|$(date +%s)" > "${dir}/proposal-status"
echo "proposal-status|${status}|$(date +%s)" > "${dir}/agent-findings"

echo "Set ${dir}/proposal-status to ${status}"

