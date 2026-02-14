#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"
# DECISION: Use a single runner that forks by persisted mode to keep research behavior deterministic and auditable.

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/run-research.sh "<research question>" [output-file]

Behavior:
  - mode is read from .codex/research-mode (codex-only|multi-provider)
  - codex-only: writes a structured Codex research brief scaffold
  - multi-provider: queries OpenAI + Perplexity + Gemini and writes a synthesis report
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1"
    exit 1
  fi
}

read_mode() {
  local mode_file mode
  mode_file="${RESEARCH_MODE_FILE:-$(resolve_state_file_for_read "research-mode")}" 
  if [[ ! -f "${mode_file}" ]]; then
    echo "ERROR: research mode not set"
    echo "Choose mode first: ./scripts/run-cycle.sh research-mode codex-only|multi-provider"
    exit 1
  fi
  mode="$(cut -d'|' -f1 "${mode_file}" || true)"
  if [[ "${mode}" != "codex-only" && "${mode}" != "multi-provider" ]]; then
    echo "ERROR: invalid research mode '${mode:-unknown}'"
    exit 1
  fi
  echo "${mode}"
}

load_secrets() {
  local secrets_file
  secrets_file="$(./scripts/research-secrets.sh path)"
  if [[ -f "${secrets_file}" ]]; then
    # shellcheck disable=SC1090
    source "${secrets_file}"
  fi
}

provider_chat_completion() {
  local provider="${1}"
  local endpoint="${2}"
  local api_key="${3}"
  local model="${4}"
  local system_prompt="${5}"
  local user_prompt="${6}"
  local output_json="${7}"

  local payload
  payload="$(jq -n \
    --arg model "${model}" \
    --arg system_prompt "${system_prompt}" \
    --arg user_prompt "${user_prompt}" \
    '{model:$model,messages:[{role:"system",content:$system_prompt},{role:"user",content:$user_prompt}],temperature:0.2}')"

  if ! curl -sS "${endpoint}" \
    -H "Authorization: Bearer ${api_key}" \
    -H "Content-Type: application/json" \
    -d "${payload}" > "${output_json}"; then
    echo "ERROR: ${provider} request failed"
    return 1
  fi
}

extract_chat_text() {
  local json_file="${1}"
  jq -r '.choices[0].message.content // empty' "${json_file}"
}

run_gemini() {
  local api_key="${1}"
  local model="${2}"
  local system_prompt="${3}"
  local user_prompt="${4}"
  local output_json="${5}"

  local payload
  payload="$(jq -n \
    --arg sys "${system_prompt}" \
    --arg usr "${user_prompt}" \
    '{systemInstruction:{parts:[{text:$sys}]},contents:[{role:"user",parts:[{text:$usr}]}]}')"

  if ! curl -sS "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${api_key}" \
    -H "Content-Type: application/json" \
    -d "${payload}" > "${output_json}"; then
    echo "ERROR: Gemini request failed"
    return 1
  fi
}

extract_gemini_text() {
  local json_file="${1}"
  jq -r '.candidates[0].content.parts[0].text // empty' "${json_file}"
}

question="${1:-}"
if [[ -z "${question}" ]]; then
  usage
  exit 1
fi

out_file="${2:-}"
mode="$(read_mode)"

ts="$(date -u +%Y%m%d-%H%M%SZ)"
out_dir="research"
raw_dir="${out_dir}/raw"
mkdir -p "${out_dir}" "${raw_dir}"

if [[ -z "${out_file}" ]]; then
  out_file="${out_dir}/${ts}-${mode}-research.md"
fi

if [[ "${mode}" == "codex-only" ]]; then
  cat > "${out_file}" <<EOF_DOC
# Research Brief

- mode: codex-only
- generated_utc: ${ts}
- question: ${question}

## Findings (Codex Web Research)

- Add validated sources and findings here.

## Option Analysis

- Option A:
- Option B:

## Recommendation

- Recommended direction:
- Why:
- Risks:

## Proposal Ingestion

- Add key points into 'PROPOSAL.md' sections:
  - '## Research Findings'
  - '## Options and Trade-Offs'
  - '## Recommended Architecture'
EOF_DOC
  echo "Wrote codex-only research brief: ${out_file}"
  exit 0
fi

require_cmd curl
require_cmd jq

./scripts/research-secrets.sh validate multi-provider >/dev/null
load_secrets

system_prompt="You are a senior software research assistant. Provide concrete, implementation-relevant guidance with assumptions, trade-offs, and risks."
openai_model="${OPENAI_RESEARCH_MODEL:-gpt-4o-mini}"
pplx_model="${PERPLEXITY_RESEARCH_MODEL:-sonar-pro}"
gemini_model="${GEMINI_RESEARCH_MODEL:-gemini-2.0-flash}"

openai_json="${raw_dir}/${ts}-openai.json"
pplx_json="${raw_dir}/${ts}-perplexity.json"
gemini_json="${raw_dir}/${ts}-gemini.json"

provider_chat_completion "OpenAI" "https://api.openai.com/v1/chat/completions" "${OPENAI_API_KEY}" "${openai_model}" "${system_prompt}" "${question}" "${openai_json}"
provider_chat_completion "Perplexity" "https://api.perplexity.ai/chat/completions" "${PPLX_API_KEY}" "${pplx_model}" "${system_prompt}" "${question}" "${pplx_json}"
run_gemini "${GEMINI_API_KEY}" "${gemini_model}" "${system_prompt}" "${question}" "${gemini_json}"

openai_text="$(extract_chat_text "${openai_json}")"
pplx_text="$(extract_chat_text "${pplx_json}")"
gemini_text="$(extract_gemini_text "${gemini_json}")"

if [[ -z "${openai_text}" ]]; then
  echo "ERROR: OpenAI response content missing"
  jq -r '.error.message // "no error message"' "${openai_json}" || true
  exit 1
fi
if [[ -z "${pplx_text}" ]]; then
  echo "ERROR: Perplexity response content missing"
  jq -r '.error.message // "no error message"' "${pplx_json}" || true
  exit 1
fi
if [[ -z "${gemini_text}" ]]; then
  echo "ERROR: Gemini response content missing"
  jq -r '.error.message // "no error message"' "${gemini_json}" || true
  exit 1
fi

synth_prompt=$(cat <<EOF_SYNTH
Research question:
${question}

Provider outputs:

[OpenAI]
${openai_text}

[Perplexity]
${pplx_text}

[Gemini]
${gemini_text}

Create a synthesis with these exact markdown headings:
## Consensus
## Meaningful Differences
## Recommended Direction
## Risks and Unknowns
## What to Put in PROPOSAL.md

Be specific and implementation-oriented.
EOF_SYNTH
)

synth_json="${raw_dir}/${ts}-synthesis.json"
provider_chat_completion "OpenAI-Synthesis" "https://api.openai.com/v1/chat/completions" "${OPENAI_API_KEY}" "${OPENAI_SYNTHESIS_MODEL:-gpt-4o-mini}" "You synthesize cross-provider research findings." "${synth_prompt}" "${synth_json}"
synthesis_text="$(extract_chat_text "${synth_json}")"

if [[ -z "${synthesis_text}" ]]; then
  synthesis_text=$'## Consensus\n- Manual synthesis required (synthesis model returned empty content).\n\n## Meaningful Differences\n- Review provider sections below.\n\n## Recommended Direction\n- Derive recommendation from consensus + constraints.\n\n## Risks and Unknowns\n- Capture unresolved items.\n\n## What to Put in PROPOSAL.md\n- Update Research Findings, Options and Trade-Offs, and Recommended Architecture.'
fi

cat > "${out_file}" <<EOF_DOC
# Multi-Provider Research Synthesis

- mode: multi-provider
- generated_utc: ${ts}
- question: ${question}
- models:
  - OpenAI: ${openai_model}
  - Perplexity: ${pplx_model}
  - Gemini: ${gemini_model}

## OpenAI Output

${openai_text}

## Perplexity Output

${pplx_text}

## Gemini Output

${gemini_text}

${synthesis_text}

## Raw Artifacts

- ${openai_json}
- ${pplx_json}
- ${gemini_json}
- ${synth_json}
EOF_DOC

echo "Wrote multi-provider synthesis report: ${out_file}"
echo "Next: ingest findings into PROPOSAL.md (Research Findings, Options and Trade-Offs, Recommended Architecture)."
