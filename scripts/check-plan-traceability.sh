#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

plan_file="${1:-MASTER_PLAN.md}"

if [[ ! -f "${plan_file}" ]]; then
  echo "ERROR: ${plan_file} not found"
  exit 1
fi

dir="$(state_dir_writable)"

req_ids="$(rg -o 'REQ-[A-Z0-9]+-[0-9]{3}' "${plan_file}" | sort -u || true)"
dec_ids="$(rg -o 'DEC-[A-Z0-9]+-[0-9]{3}' "${plan_file}" | sort -u || true)"

req_count="$(echo "${req_ids}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
dec_count="$(echo "${dec_ids}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"

missing_decision_links="$(rg -n '^[[:space:]]*-[[:space:]]*DEC-[A-Z0-9]+-[0-9]{3}:' "${plan_file}" | rg -vc 'Addresses:[[:space:]]*REQ-' || true)"
if [[ -z "${missing_decision_links}" ]]; then
  missing_decision_links=0
fi

addresses_req_ids="$(rg -o 'Addresses:[^\n]*' "${plan_file}" | rg -o 'REQ-[A-Z0-9]+-[0-9]{3}' | sort -u || true)"
unaddressed_req_count=0
while IFS= read -r req; do
  [[ -z "${req}" ]] && continue
  if ! echo "${addresses_req_ids}" | rg -q "^${req}$"; then
    unaddressed_req_count=$((unaddressed_req_count + 1))
  fi
done <<< "${req_ids}"

epoch="$(date +%s)"
{
  echo "req_count|${req_count}"
  echo "dec_count|${dec_count}"
  echo "missing_decision_links|${missing_decision_links}"
  echo "unaddressed_req_count|${unaddressed_req_count}"
  echo "timestamp|${epoch}"
} > "${dir}/plan-drift"

if [[ "${STRICT_TRACEABILITY:-0}" == "1" ]]; then
  if (( missing_decision_links > 0 || unaddressed_req_count > 0 )); then
    echo "ERROR: traceability gate failed"
    echo "  missing_decision_links=${missing_decision_links}"
    echo "  unaddressed_req_count=${unaddressed_req_count}"
    exit 1
  fi
fi

if (( req_count == 0 || dec_count == 0 )); then
  echo "WARN: traceability baseline is thin (REQ=${req_count}, DEC=${dec_count})"
else
  echo "OK: traceability snapshot written (${dir}/plan-drift)"
fi
