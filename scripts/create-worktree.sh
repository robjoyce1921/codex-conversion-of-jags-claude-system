#!/usr/bin/env bash
set -euo pipefail

raw_name="${1:-}"
if [[ -z "${raw_name}" ]]; then
  echo "Usage: $0 <feature-name>"
  exit 1
fi

name="$(echo "${raw_name}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
if [[ -z "${name}" ]]; then
  echo "ERROR: feature name sanitized to empty value"
  exit 1
fi

branch="codex/${name}"
path=".worktrees/${name}"

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo "ERROR: branch already exists: ${branch}"
  exit 1
fi

if [[ -e "${path}" ]]; then
  echo "ERROR: worktree path already exists: ${path}"
  exit 1
fi

mkdir -p .worktrees
git worktree add "${path}" -b "${branch}"
echo "Created worktree: ${path} on branch ${branch}"

