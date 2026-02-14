#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

dir="$(state_dir_writable)"
{
  echo "timestamp|$(date +%s)"
  echo "[staged]"
  git diff --cached --name-only | sed '/^[[:space:]]*$/d' || true
  echo "[unstaged]"
  git diff --name-only | sed '/^[[:space:]]*$/d' || true
  echo "[untracked]"
  git ls-files --others --exclude-standard | sed '/^[[:space:]]*$/d' || true
} > "${dir}/session-changes"

echo "Updated ${dir}/session-changes"
