#!/usr/bin/env bash
set -euo pipefail

status="${1:-}"
if [[ "${status}" != "pending" && "${status}" != "verified" ]]; then
  echo "Usage: $0 pending|verified"
  exit 1
fi

mkdir -p .codex
echo "${status}|$(date +%s)" > .codex/proof-status

echo "Set .codex/proof-status to ${status}"

