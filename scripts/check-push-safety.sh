#!/usr/bin/env bash
set -euo pipefail

remote_name="${1:-unknown}"
remote_url="${2:-unknown}"

zero_sha='0000000000000000000000000000000000000000'

echo "Checking push safety for ${remote_name} (${remote_url})"

while read -r local_ref local_sha remote_ref remote_sha; do
  [[ -z "${local_ref:-}" ]] && continue

  if [[ "${remote_ref}" =~ refs/heads/(main|master)$ ]]; then
    if [[ "${ALLOW_MAIN_PUSH:-0}" != "1" ]]; then
      echo "ERROR: Pushes to ${remote_ref} are blocked by policy."
      echo "Use a feature branch or set ALLOW_MAIN_PUSH=1 for explicit override."
      exit 1
    fi
  fi

  if [[ "${local_sha}" == "${zero_sha}" ]]; then
    # Branch delete push; allow by default.
    continue
  fi

  if [[ "${remote_sha}" == "${zero_sha}" ]]; then
    # New branch push; always fast-forward.
    continue
  fi

  if ! git merge-base --is-ancestor "${remote_sha}" "${local_sha}"; then
    if [[ "${ALLOW_NON_FF_PUSH:-0}" != "1" ]]; then
      echo "ERROR: Non-fast-forward push detected (${remote_ref})."
      echo "Use --force-with-lease intentionally and set ALLOW_NON_FF_PUSH=1."
      exit 1
    fi
  fi
done

echo "OK: push safety checks passed"

