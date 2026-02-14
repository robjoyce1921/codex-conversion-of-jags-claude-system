#!/usr/bin/env bash
set -euo pipefail

max_files="${MAX_FILES:-10}"
count="$(git diff --cached --name-only | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"

if (( count > max_files )); then
  echo "ERROR: ${count} files staged (max ${max_files}). Split into smaller passes."
  exit 1
fi

echo "OK: staged file count ${count}/${max_files}"

