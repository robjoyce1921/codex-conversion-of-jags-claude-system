#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

mode="${1:-}"
case "${mode}" in
  codex-only|multi-provider)
    ;;
  *)
    echo "Usage: $0 codex-only|multi-provider"
    exit 1
    ;;
esac

# DECISION: Persist research mode as state so orchestration and checks remain deterministic across sessions.
dir="$(state_dir_writable)"
now="$(date +%s)"
echo "${mode}|${now}" > "${dir}/research-mode"
echo "research-mode|${mode}|${now}" > "${dir}/agent-findings"

echo "Set ${dir}/research-mode to ${mode}"
