#!/usr/bin/env bash
set -euo pipefail

threshold="${DECISION_THRESHOLD_ADDED_LINES:-30}"
pattern='\.(c|cc|cpp|h|hpp|go|java|js|jsx|py|rb|rs|sh|swift|ts|tsx|zsh)$'

candidate_files=()
while IFS= read -r file; do
  candidate_files+=("${file}")
done < <(git diff --cached --name-only --diff-filter=ACMR | rg "${pattern}" || true)

if [[ "${#candidate_files[@]}" -eq 0 ]]; then
  echo "OK: no staged code files for decision check"
  exit 0
fi

missing=()
for file in "${candidate_files[@]}"; do
  if ! git cat-file -e ":${file}" 2>/dev/null; then
    continue
  fi

  added="$(git diff --cached --numstat -- "${file}" | awk '{print $1}')"
  if [[ "${added}" == "-" || -z "${added}" ]]; then
    continue
  fi

  if (( added >= threshold )); then
    if ! git show ":${file}" | rg -q 'DECISION[[:space:]]*[:(]'; then
      missing+=("${file}")
    fi
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "ERROR: Decision annotation required for larger edits (>=${threshold} added lines):"
  printf '  - %s\n' "${missing[@]}"
  echo "Add inline 'DECISION:' notes and update MASTER_PLAN.md Decisions."
  exit 1
fi

echo "OK: decision annotation check passed"
