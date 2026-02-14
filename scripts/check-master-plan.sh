#!/usr/bin/env bash
set -euo pipefail

plan_file="${1:-MASTER_PLAN.md}"

if [[ ! -f "${plan_file}" ]]; then
  echo "ERROR: ${plan_file} is required."
  exit 1
fi

required_headers=(
  "## Problem"
  "## Constraints"
  "## Plan"
  "## Acceptance Criteria"
  "## Progress Log"
  "## Decisions"
  "## Handoff"
)

for header in "${required_headers[@]}"; do
  if ! grep -Fqx "${header}" "${plan_file}"; then
    echo "ERROR: Missing required heading '${header}' in ${plan_file}"
    exit 1
  fi
done

if git rev-parse --git-dir >/dev/null 2>&1; then
  staged_files="$(git diff --cached --name-only)"
  if [[ -n "${staged_files}" ]]; then
    code_staged="$(echo "${staged_files}" | rg -v "^${plan_file}$" || true)"
    plan_staged="$(echo "${staged_files}" | rg "^${plan_file}$" || true)"
    if [[ -n "${code_staged}" && -z "${plan_staged}" ]]; then
      echo "ERROR: Stage ${plan_file} together with code changes."
      exit 1
    fi
  fi
fi

echo "OK: ${plan_file} validated"

