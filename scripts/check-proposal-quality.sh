#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"
# DECISION: Enforce proposal completeness structurally so research/planning quality is mechanically checked.

proposal_file="${1:-PROPOSAL.md}"
min_words="${PROPOSAL_MIN_WORDS:-250}"

if [[ ! -f "${proposal_file}" ]]; then
  if [[ "${PROPOSAL_OPTIONAL:-0}" == "1" ]]; then
    echo "WARN: ${proposal_file} not found (optional mode)"
    exit 0
  fi
  echo "ERROR: ${proposal_file} is required."
  echo "Run: ./scripts/init-proposal.sh"
  exit 1
fi

required_headers=(
  "## Original Intent"
  "## Problem Decomposition"
  "## Goals"
  "## Non-Goals"
  "## User Requirements (P0/P1/P2)"
  "## Success Metrics"
  "## Research Mode"
  "## Research Plan"
  "## Research Findings"
  "## Options and Trade-Offs"
  "## Recommended Architecture"
  "## Phase Plan"
  "## Risks and Mitigations"
  "## Validation and Evaluation Plan"
  "## User Review Checklist"
  "## Approval Status"
)

missing=()
for header in "${required_headers[@]}"; do
  if ! grep -Fqx "${header}" "${proposal_file}"; then
    missing+=("${header}")
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  dir="$(state_dir_writable)"
  {
    echo "proposal-quality|missing required sections|$(date +%s)"
    printf 'missing|%s\n' "${missing[@]}"
  } > "${dir}/agent-findings"
  echo "ERROR: proposal is missing required sections:"
  printf '  - %s\n' "${missing[@]}"
  exit 1
fi

word_count="$(wc -w < "${proposal_file}" | tr -d ' ')"
if (( word_count < min_words )); then
  dir="$(state_dir_writable)"
  echo "proposal-quality|proposal too short (${word_count} words, min ${min_words})|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proposal is not robust enough (${word_count} words, min ${min_words})"
  exit 1
fi

if ! rg -q 'Option A|Option B' "${proposal_file}"; then
  dir="$(state_dir_writable)"
  echo "proposal-quality|missing option analysis (Option A/B)|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proposal must include explicit option analysis (Option A/B at minimum)"
  exit 1
fi

if ! rg -q -e '\bcodex-only\b|\bmulti-provider\b' "${proposal_file}"; then
  dir="$(state_dir_writable)"
  echo "proposal-quality|missing explicit research mode value (codex-only|multi-provider)|$(date +%s)" > "${dir}/agent-findings"
  echo "ERROR: proposal must declare research mode (codex-only or multi-provider)"
  exit 1
fi

research_mode_file="${RESEARCH_MODE_FILE:-$(resolve_state_file_for_read "research-mode")}"
if [[ -f "${research_mode_file}" ]]; then
  selected_mode="$(cut -d'|' -f1 "${research_mode_file}" || true)"
  if [[ "${selected_mode}" == "codex-only" || "${selected_mode}" == "multi-provider" ]]; then
    if ! rg -q "${selected_mode}" "${proposal_file}"; then
      dir="$(state_dir_writable)"
      echo "proposal-quality|proposal research mode does not match state (${selected_mode})|$(date +%s)" > "${dir}/agent-findings"
      echo "ERROR: proposal research mode does not match selected mode (${selected_mode})"
      exit 1
    fi
  fi
fi

if rg -q '\bmulti-provider\b' "${proposal_file}"; then
  if ! rg -q 'OpenAI' "${proposal_file}" || ! rg -q 'Perplexity' "${proposal_file}" || ! rg -q 'Gemini' "${proposal_file}"; then
    dir="$(state_dir_writable)"
    echo "proposal-quality|multi-provider mode missing provider coverage details|$(date +%s)" > "${dir}/agent-findings"
    echo "ERROR: multi-provider proposal must address OpenAI, Perplexity, and Gemini findings"
    exit 1
  fi
fi

if ! rg -q 'pending|approved|needs-revision' "${proposal_file}"; then
  echo "WARN: Approval Status values not found in ${proposal_file}"
fi

echo "OK: proposal quality check passed (${proposal_file}, ${word_count} words)"
